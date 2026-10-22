import os
import sys
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

# Ensure project root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, precision_score, recall_score, f1_score, accuracy_score
from sklearn.model_selection import train_test_split

from backend.ml.features import FEATURE_NAMES, calculate_vpd

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("agrisense.ml.train")

MODELS_DIR = Path(__file__).resolve().parent / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

MODEL_OUTPUT_PATH = MODELS_DIR / "irrigation_model.joblib"
METADATA_OUTPUT_PATH = MODELS_DIR / "model_metadata.json"

def generate_agronomic_reference_dataset(n_samples: int = 2500, random_seed: int = 42) -> pd.DataFrame:
    """
    Synthesizes a scientifically grounded agronomic training dataset based on FAO-56
    guidelines (soil water retention characteristics, crop depletion factors, and evaporative demand).
    """
    np.random.seed(random_seed)

    # 1. Soil types: 0 = Sand (low water retention), 1 = Loam (medium), 2 = Clay (high)
    soil_type_code = np.random.choice([0, 1, 2], size=n_samples, p=[0.25, 0.50, 0.25])

    # 2. Crop types: 0 = General, 1 = Wheat, 2 = Tomato, 3 = Maize
    crop_type_code = np.random.choice([0, 1, 2, 3], size=n_samples, p=[0.3, 0.25, 0.25, 0.2])

    # 3. Microclimate: Temperature (15 to 42 °C), Humidity (20 to 85 %)
    temp_c = np.random.uniform(15.0, 42.0, size=n_samples)
    humidity_pct = np.random.uniform(20.0, 85.0, size=n_samples)

    # 4. VPD calculation
    vpd_kpa = np.array([calculate_vpd(t, h) for t, h in zip(temp_c, humidity_pct)])

    # 5. Soil Moisture estimate (0 to 100%)
    # Varied across the spectrum
    soil_moisture = np.random.uniform(5.0, 95.0, size=n_samples)

    # 6. Raw ESP32 ADC (inverse relationship with moisture: ~4095 is dry, ~1500 is wet)
    # Add minor sensor noise
    adc_noise = np.random.normal(0, 40, size=n_samples)
    soil_ao_raw = 4095 - ((soil_moisture / 100.0) * (4095 - 1400)) + adc_noise
    soil_ao_raw = np.clip(soil_ao_raw, 0, 4095).astype(int)

    # 7. Ground truth labeling based on agronomic thresholds:
    # Sand wilting point ~ 10-15%, field capacity ~ 25% -> threshold ~ 20%
    # Loam wilting point ~ 15-20%, field capacity ~ 45% -> threshold ~ 35%
    # Clay wilting point ~ 22-28%, field capacity ~ 60% -> threshold ~ 45%
    base_thresholds = {0: 22.0, 1: 35.0, 2: 45.0}

    # High evaporative demand (VPD > 1.8 kPa or Temp > 32°C) increases depletion urgency
    labels = []
    for i in range(n_samples):
        st = soil_type_code[i]
        sm = soil_moisture[i]
        vpd = vpd_kpa[i]
        temp = temp_c[i]
        crop = crop_type_code[i]

        threshold = base_thresholds[st]
        # Sensitive crops (e.g. Tomato = 2) require earlier irrigation (+5% buffer)
        if crop == 2:
            threshold += 5.0

        # Atmospheric stress adjustment
        if vpd > 2.0 or temp > 33.0:
            threshold += 4.0

        # Irrigation needed if current moisture is below stress threshold
        need_irrigation = 1 if sm < threshold else 0
        labels.append(need_irrigation)

    df = pd.DataFrame({
        "soil_moisture_estimate_percent": np.round(soil_moisture, 1),
        "soil_ao_raw": soil_ao_raw,
        "temperature_c": np.round(temp_c, 1),
        "humidity_percent": np.round(humidity_pct, 1),
        "vpd_kpa": vpd_kpa,
        "soil_type_code": soil_type_code,
        "crop_type_code": crop_type_code,
        "irrigation_needed": labels,
    })

    return df

def train_and_evaluate():
    """Trains the baseline model and saves verified artifacts."""
    logger.info("Generating reference agronomic training dataset...")
    df = generate_agronomic_reference_dataset(n_samples=3000, random_seed=42)

    X = df[FEATURE_NAMES]
    y = df["irrigation_needed"]

    # Train / Test split (80% train, 20% held-out test)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    logger.info("Dataset shape: Train=%s, Test=%s", X_train.shape, X_test.shape)
    logger.info("Class distribution in Test: %s", dict(y_test.value_counts()))

    # 1. Baseline: Logistic Regression
    lr = LogisticRegression(max_iter=500, random_state=42)
    lr.fit(X_train, y_train)
    y_pred_lr = lr.predict(X_test)
    f1_lr = f1_score(y_test, y_pred_lr)
    logger.info("Baseline Logistic Regression Test F1: %.4f", f1_lr)

    # 2. Random Forest Classifier
    rf = RandomForestClassifier(
        n_estimators=100,
        max_depth=7,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
    )
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)

    # Metrics
    acc = accuracy_score(y_test, y_pred_rf)
    prec = precision_score(y_test, y_pred_rf)
    rec = recall_score(y_test, y_pred_rf)
    f1 = f1_score(y_test, y_pred_rf)
    cm = confusion_matrix(y_test, y_pred_rf).tolist()

    logger.info("Random Forest Evaluation:")
    logger.info("  Accuracy:  %.4f", acc)
    logger.info("  Precision: %.4f", prec)
    logger.info("  Recall:    %.4f", rec)
    logger.info("  F1 Score:  %.4f", f1)
    logger.info("  Confusion Matrix: %s", cm)

    # Save model artifact
    joblib.dump(rf, MODEL_OUTPUT_PATH)
    logger.info("Saved model to %s", MODEL_OUTPUT_PATH)

    # Feature importances
    feature_importances = dict(zip(FEATURE_NAMES, [round(float(imp), 4) for imp in rf.feature_importances_]))

    metadata = {
        "model_type": "RandomForestClassifier",
        "model_version": "v1.0.0-rf-agronomic",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "features": FEATURE_NAMES,
        "feature_importances": feature_importances,
        "evaluation_metrics": {
            "accuracy": round(float(acc), 4),
            "precision": round(float(prec), 4),
            "recall": round(float(rec), 4),
            "f1_score": round(float(f1), 4),
            "confusion_matrix": cm,
            "baseline_logistic_regression_f1": round(float(f1_lr), 4),
        },
        "training_samples": len(X_train),
        "test_samples": len(X_test),
        "status": "trained_and_validated",
    }

    with open(METADATA_OUTPUT_PATH, "w") as f:
        json.dump(metadata, f, indent=2)

    logger.info("Saved metadata to %s", METADATA_OUTPUT_PATH)
    return metadata

if __name__ == "__main__":
    train_and_evaluate()
