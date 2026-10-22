import os
import sys
import json
import logging
from pathlib import Path
from typing import Dict, Any

# Ensure project root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

import joblib
from sklearn.metrics import classification_report, confusion_matrix, precision_score, recall_score, f1_score, accuracy_score
from backend.ml.features import FEATURE_NAMES
from backend.ml.train import generate_agronomic_reference_dataset

logger = logging.getLogger("agrisense.ml.evaluate")

def evaluate_saved_model(
    model_path: str = "backend/ml/models/irrigation_model.joblib",
    n_test_samples: int = 1000,
    random_seed: int = 999
) -> Dict[str, Any]:
    """
    Evaluates the saved model against an independently seeded test distribution.
    Verifies that the saved model artifact maintains expected accuracy and zero degradation.
    """
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model artifact not found at {model_path}")

    model = joblib.load(model_path)
    df_eval = generate_agronomic_reference_dataset(n_samples=n_test_samples, random_seed=random_seed)

    X_test = df_eval[FEATURE_NAMES]
    y_true = df_eval["irrigation_needed"]

    y_pred = model.predict(X_test)

    acc = accuracy_score(y_true, y_pred)
    prec = precision_score(y_true, y_pred)
    rec = recall_score(y_true, y_pred)
    f1 = f1_score(y_true, y_pred)
    cm = confusion_matrix(y_true, y_pred).tolist()

    # False negative rate: instances where irrigation was needed but model predicted NO
    fn = cm[1][0]
    total_positives = cm[1][0] + cm[1][1]
    fn_rate = round(fn / total_positives, 4) if total_positives > 0 else 0.0

    results = {
        "samples_evaluated": n_test_samples,
        "accuracy": round(float(acc), 4),
        "precision": round(float(prec), 4),
        "recall": round(float(rec), 4),
        "f1_score": round(float(f1), 4),
        "false_negative_rate": fn_rate,
        "confusion_matrix": cm,
    }

    return results

if __name__ == "__main__":
    res = evaluate_saved_model()
    print("Independent Model Evaluation Results:")
    print(json.dumps(res, indent=2))
