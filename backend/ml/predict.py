import os
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, Optional, List
import joblib
import pandas as pd

from backend.ml.features import (
    FEATURE_NAMES,
    extract_features_from_reading,
    calculate_vpd,
)

logger = logging.getLogger("agrisense.ml.predict")

class IrrigationPredictor:
    """Loads trained ML model and handles irrigation-need inference and explainability."""

    def __init__(self, model_path: str, metadata_path: str):
        self.model_path = model_path
        self.metadata_path = metadata_path
        self.model = None
        self.metadata: Dict[str, Any] = {}
        self.is_loaded = False
        self._load_model()

    def _load_model(self):
        """Loads model and metadata from disk."""
        if not os.path.exists(self.model_path):
            logger.warning("ML model file not found at: %s", self.model_path)
            self.is_loaded = False
            return

        try:
            self.model = joblib.load(self.model_path)
            if os.path.exists(self.metadata_path):
                with open(self.metadata_path, "r") as f:
                    self.metadata = json.load(f)
            self.is_loaded = True
            logger.info("Successfully loaded ML model from: %s", self.model_path)
        except Exception as e:
            logger.error("Failed to load ML model artifact: %s", e)
            self.is_loaded = False

    def predict(
        self,
        reading: Dict[str, Any],
        crop_type: str = "general",
        soil_type: str = "loam",
    ) -> Dict[str, Any]:
        """
        Executes inference for the given sensor reading.
        Returns a structured prediction dictionary.
        """
        now = datetime.now(timezone.utc)
        input_ts = reading.get("timestamp") or now.isoformat()

        if not self.is_loaded or self.model is None:
            return {
                "available": False,
                "prediction_type": "irrigation_need",
                "irrigation_needed": None,
                "confidence": None,
                "model_version": None,
                "input_timestamp": input_ts,
                "prediction_timestamp": now.isoformat(),
                "explanation": ["Trained ML model artifact is not loaded or unavailable."],
                "error": "MODEL_UNAVAILABLE",
            }

        try:
            # Extract features aligned with trained schema
            df_features = extract_features_from_reading(reading, soil_type=soil_type, crop_type=crop_type)

            # Predict class (0 = No, 1 = Yes)
            pred_class = int(self.model.predict(df_features)[0])
            irrigation_needed = bool(pred_class == 1)

            # Confidence probability
            confidence = None
            if hasattr(self.model, "predict_proba"):
                probs = self.model.predict_proba(df_features)[0]
                # Probability corresponding to the chosen class
                confidence = round(float(probs[pred_class]), 3)

            # Generate grounded agronomic explanations
            explanations = self._generate_explanations(
                reading=reading,
                df_features=df_features,
                irrigation_needed=irrigation_needed,
                soil_type=soil_type,
                crop_type=crop_type,
            )

            calibrated = reading.get("calibrated", {})
            return {
                "available": True,
                "prediction_type": "irrigation_need",
                "irrigation_needed": irrigation_needed,
                "confidence": confidence,
                "model_version": self.metadata.get("model_version", "v1.0.0-rf"),
                "input_timestamp": input_ts,
                "prediction_timestamp": now.isoformat(),
                "explanation": explanations,
                "features_used": {
                    "soil_moisture_estimate_percent": calibrated.get("soil_moisture_estimate_percent"),
                    "temperature_c": calibrated.get("temperature_c"),
                    "humidity_percent": calibrated.get("humidity_percent"),
                    "vpd_kpa": float(df_features["vpd_kpa"].iloc[0]),
                    "soil_type": soil_type,
                    "crop_type": crop_type,
                },
                "evaluation_metrics": self.metadata.get("evaluation_metrics", {}),
            }
        except Exception as e:
            logger.error("Error during ML inference: %s", e)
            return {
                "available": False,
                "prediction_type": "irrigation_need",
                "irrigation_needed": None,
                "confidence": None,
                "model_version": self.metadata.get("model_version"),
                "input_timestamp": input_ts,
                "prediction_timestamp": now.isoformat(),
                "explanation": [f"Inference error: {str(e)}"],
                "error": "INFERENCE_FAILED",
            }

    def _generate_explanations(
        self,
        reading: Dict[str, Any],
        df_features: pd.DataFrame,
        irrigation_needed: bool,
        soil_type: str,
        crop_type: str,
    ) -> List[str]:
        explanations = []
        calibrated = reading.get("calibrated", {})
        sm = calibrated.get("soil_moisture_estimate_percent", 0.0)
        temp = calibrated.get("temperature_c", 25.0)
        humid = calibrated.get("humidity_percent", 50.0)
        vpd = float(df_features["vpd_kpa"].iloc[0])

        if irrigation_needed:
            explanations.append(
                f"Soil moisture is at {sm}%, indicating moisture deficit for {soil_type} soil under {crop_type} cultivation."
            )
            if vpd > 1.8:
                explanations.append(
                    f"Atmospheric vapor pressure deficit (VPD) is elevated at {vpd} kPa, accelerating crop transpiration demand."
                )
            if temp and temp > 30.0:
                explanations.append(
                    f"Ambient temperature is warm ({temp}°C), increasing soil surface evaporation."
                )
        else:
            explanations.append(
                f"Soil moisture is adequate ({sm}%) within the optimal retention zone for {soil_type} soil."
            )
            if vpd <= 1.5:
                explanations.append(
                    f"Evaporative demand is moderate (VPD {vpd} kPa, humidity {humid}%), minimizing immediate moisture loss."
                )

        return explanations
