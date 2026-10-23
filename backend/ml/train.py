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
from sklearn.metrics import confusion_matrix, precision_score, recall_score, f1_score, accuracy_score
from sklearn.model_selection import train_test_split

from backend.ml.features import FEATURE_NAMES, calculate_vpd
from backend.ml.crop_model import CropPredictor
from backend.ml.fertilizer_model import FertilizerPredictor

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("agrisense.ml.train")

MODELS_DIR = Path(__file__).resolve().parent / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

IRRIGATION_MODEL_PATH = MODELS_DIR / "irrigation_model.joblib"
CROP_MODEL_PATH = MODELS_DIR / "crop_model.joblib"
FERTILIZER_MODEL_PATH = MODELS_DIR / "fertilizer_model.joblib"
METADATA_OUTPUT_PATH = MODELS_DIR / "model_metadata.json"


def generate_agronomic_reference_dataset(n_samples: int = 2500, random_seed: int = 42) -> pd.DataFrame:
    """Synthesizes an agronomic training dataset based on FAO-56 guidelines."""
    np.random.seed(random_seed)

    soil_type_code = np.random.choice([0, 1, 2], size=n_samples, p=[0.25, 0.50, 0.25])
    crop_type_code = np.random.choice([0, 1, 2, 3], size=n_samples, p=[0.3, 0.25, 0.25, 0.2])

    temp_c = np.random.uniform(15.0, 42.0, size=n_samples)
    humidity_pct = np.random.uniform(20.0, 85.0, size=n_samples)
    vpd_kpa = np.array([calculate_vpd(t, h) for t, h in zip(temp_c, humidity_pct)])

    soil_moisture = np.random.uniform(5.0, 95.0, size=n_samples)
    adc_noise = np.random.normal(0, 40, size=n_samples)
    soil_ao_raw = 4095 - ((soil_moisture / 100.0) * (4095 - 1400)) + adc_noise
    soil_ao_raw = np.clip(soil_ao_raw, 0, 4095).astype(int)

    base_thresholds = {0: 22.0, 1: 35.0, 2: 45.0}

    labels = []
    for i in range(n_samples):
        st = soil_type_code[i]
        sm = soil_moisture[i]
        vpd = vpd_kpa[i]
        temp = temp_c[i]
        crop = crop_type_code[i]

        threshold = base_thresholds[st]
        if crop == 2:  # Tomato
            threshold += 5.0
        if vpd > 2.0 or temp > 33.0:
            threshold += 4.0

        labels.append(1 if sm < threshold else 0)

    return pd.DataFrame({
        "soil_moisture_estimate_percent": np.round(soil_moisture, 1),
        "soil_ao_raw": soil_ao_raw,
        "temperature_c": np.round(temp_c, 1),
        "humidity_percent": np.round(humidity_pct, 1),
        "vpd_kpa": vpd_kpa,
        "soil_type_code": soil_type_code,
        "crop_type_code": crop_type_code,
        "irrigation_needed": labels,
    })


def train_irrigation_model():
    """Trains and returns the irrigation prediction model."""
    logger.info("--- Training Irrigation Model ---")
    df = generate_agronomic_reference_dataset(n_samples=3000, random_seed=42)

    X = df[FEATURE_NAMES]
    y = df["irrigation_needed"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    rf = RandomForestClassifier(
        n_estimators=100,
        max_depth=7,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
    )
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)

    acc = float(accuracy_score(y_test, y_pred_rf))
    f1 = float(f1_score(y_test, y_pred_rf))
    cm = confusion_matrix(y_test, y_pred_rf).tolist()

    joblib.dump(rf, IRRIGATION_MODEL_PATH)
    logger.info("Saved Irrigation model to %s (Accuracy: %.4f, F1: %.4f)", IRRIGATION_MODEL_PATH, acc, f1)

    return {
        "accuracy": round(acc, 4),
        "f1_score": round(f1, 4),
        "confusion_matrix": cm,
    }


def train_all_models():
    """Unified entry point to train all AgriSense ML models."""
    logger.info("=== Starting AgriSense Full ML Training Pipeline ===")

    # 1. Irrigation Model
    irrigation_metrics = train_irrigation_model()

    # 2. Crop Recommendation Model
    logger.info("--- Training Crop Recommendation Model ---")
    crop_predictor = CropPredictor(model_path=str(CROP_MODEL_PATH))
    crop_acc = crop_predictor.train_and_save()

    # 3. Fertilizer Recommendation Model
    logger.info("--- Training Fertilizer Recommendation Model ---")
    fert_predictor = FertilizerPredictor(model_path=str(FERTILIZER_MODEL_PATH))
    fert_acc = fert_predictor.train_and_save()

    metadata = {
        "system": "AgriSense Precision Agronomy & IoT Suite",
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "models": {
            "irrigation": {
                "model_type": "RandomForestClassifier",
                "model_version": "v1.1.0-rf-agronomic",
                "path": str(IRRIGATION_MODEL_PATH),
                "accuracy": irrigation_metrics["accuracy"],
                "f1_score": irrigation_metrics["f1_score"],
            },
            "crop_recommendation": {
                "model_type": "RandomForestClassifier",
                "model_version": "v1.0.0-rf-crop",
                "path": str(CROP_MODEL_PATH),
                "accuracy": round(crop_acc, 4),
                "classes_count": 22,
            },
            "fertilizer_recommendation": {
                "model_type": "Pipeline(StandardScaler+OneHotEncoder+RandomForest)",
                "model_version": "v1.0.0-rf-fertilizer",
                "path": str(FERTILIZER_MODEL_PATH),
                "accuracy": round(fert_acc, 4),
                "classes_count": 7,
            },
        },
        "status": "ready_for_production",
    }

    with open(METADATA_OUTPUT_PATH, "w") as f:
        json.dump(metadata, f, indent=2)

    logger.info("=== All models trained successfully. Saved metadata to %s ===", METADATA_OUTPUT_PATH)
    return metadata


if __name__ == "__main__":
    train_all_models()
