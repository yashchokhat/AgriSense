import os
import json
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional

from backend.ml.crop_model import CropPredictor
from backend.ml.fertilizer_model import FertilizerPredictor

logger = logging.getLogger("agrisense.agronomy")


class AgronomyService:
    """
    Manages soil test profiles, merges real-time IoT telemetry with
    agronomic parameters, and orchestrates Crop and Fertilizer ML models.
    """

    # Sensible hardcoded backend defaults for missing hardware sensors (NPK and pH)
    DEFAULT_SOIL_PROFILE: Dict[str, Any] = {
        "nitrogen": 50.0,         # kg/ha
        "phosphorus": 40.0,       # kg/ha
        "potassium": 40.0,        # kg/ha
        "ph": 6.50,               # Optimal neutral soil pH
        "rainfall_mm": 100.0,     # mm average rainfall
        "soil_type": "Loamy",     # Loamy / Sandy / Black / Red / Clayey
        "target_crop": "Maize",   # Current or planned crop
        "soil_report_date": None,
        "is_manually_entered": False,
        "notes": "Using backend standard agronomic baseline. Enter soil test report values in the app to customize."
    }

    def __init__(
        self,
        crop_predictor: CropPredictor,
        fertilizer_predictor: FertilizerPredictor,
        storage_path: Optional[str] = None,
    ):
        self.crop_predictor = crop_predictor
        self.fertilizer_predictor = fertilizer_predictor
        self.storage_path = storage_path or os.environ.get("SOIL_PROFILE_PATH", "/tmp/agrisense_soil_profile.json")
        self._soil_profile = self._load_profile()

    def _load_profile(self) -> Dict[str, Any]:
        """Loads profile from shared disk storage or falls back to defaults."""
        if os.path.exists(self.storage_path):
            try:
                with open(self.storage_path, "r") as f:
                    data = json.load(f)
                    if isinstance(data, dict):
                        return data
            except Exception as e:
                logger.warning("Could not read soil profile storage from %s: %s", self.storage_path, e)
        return dict(self.DEFAULT_SOIL_PROFILE)

    def _persist_profile(self):
        """Saves current profile to shared disk storage."""
        try:
            with open(self.storage_path, "w") as f:
                json.dump(self._soil_profile, f, indent=2)
        except Exception as e:
            logger.warning("Could not persist soil profile to %s: %s", self.storage_path, e)

    def get_soil_profile(self) -> Dict[str, Any]:
        """Returns the current active soil parameters."""
        self._soil_profile = self._load_profile()
        return dict(self._soil_profile)

    def update_soil_profile(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Updates soil test report parameters."""
        self._soil_profile = self._load_profile()
        if "nitrogen" in data and data["nitrogen"] is not None:
            self._soil_profile["nitrogen"] = max(0.0, min(200.0, float(data["nitrogen"])))
        if "phosphorus" in data and data["phosphorus"] is not None:
            self._soil_profile["phosphorus"] = max(0.0, min(200.0, float(data["phosphorus"])))
        if "potassium" in data and data["potassium"] is not None:
            self._soil_profile["potassium"] = max(0.0, min(250.0, float(data["potassium"])))
        if "ph" in data and data["ph"] is not None:
            self._soil_profile["ph"] = max(3.0, min(11.0, float(data["ph"])))
        if "rainfall_mm" in data and data["rainfall_mm"] is not None:
            self._soil_profile["rainfall_mm"] = max(0.0, min(1000.0, float(data["rainfall_mm"])))
        if "soil_type" in data and data["soil_type"]:
            self._soil_profile["soil_type"] = str(data["soil_type"]).strip()
        if "target_crop" in data and data["target_crop"]:
            self._soil_profile["target_crop"] = str(data["target_crop"]).strip()

        self._soil_profile["is_manually_entered"] = True
        self._soil_profile["soil_report_date"] = datetime.now(timezone.utc).isoformat()
        self._soil_profile["notes"] = "Updated with farmer soil test report."

        self._persist_profile()
        logger.info("Updated soil profile: %s", self._soil_profile)
        return dict(self._soil_profile)

    def reset_soil_profile(self) -> Dict[str, Any]:
        """Resets soil profile back to hardcoded agronomic defaults."""
        self._soil_profile = dict(self.DEFAULT_SOIL_PROFILE)
        self._persist_profile()
        return dict(self._soil_profile)

    def get_agronomy_advisory(
        self,
        live_telemetry: Optional[Dict[str, Any]] = None,
        overrides: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Synthesizes live IoT sensor telemetry with soil test parameters
        and executes Crop & Fertilizer ML models.
        """
        now = datetime.now(timezone.utc)
        overrides = overrides or {}
        active_profile = self.get_soil_profile()

        # 1. Resolve environmental data (prioritize live IoT telemetry from ESP32)
        calibrated = (live_telemetry or {}).get("calibrated", {})
        has_live_sensors = bool(live_telemetry and live_telemetry.get("quality", {}).get("all_valid"))

        temp_c = overrides.get("temperature_c")
        if temp_c is None:
            temp_c = calibrated.get("temperature_c")
        if temp_c is None:
            temp_c = 28.0  # Default fallback temperature

        humidity = overrides.get("humidity_percent")
        if humidity is None:
            humidity = calibrated.get("humidity_percent")
        if humidity is None:
            humidity = 60.0  # Default fallback humidity

        moisture = overrides.get("soil_moisture_estimate_percent")
        if moisture is None:
            moisture = calibrated.get("soil_moisture_estimate_percent")
        if moisture is None:
            moisture = 40.0  # Default fallback soil moisture

        # 2. Resolve soil parameters (prioritize overrides, then active profile, then hardcoded)
        nitrogen = float(overrides.get("nitrogen", active_profile["nitrogen"]))
        phosphorus = float(overrides.get("phosphorus", active_profile["phosphorus"]))
        potassium = float(overrides.get("potassium", active_profile["potassium"]))
        ph = float(overrides.get("ph", active_profile["ph"]))
        rainfall = float(overrides.get("rainfall_mm", active_profile["rainfall_mm"]))
        soil_type = str(overrides.get("soil_type", active_profile["soil_type"]))
        target_crop = str(overrides.get("target_crop", active_profile["target_crop"]))

        # 3. Predict Crop
        crop_result = self.crop_predictor.predict(
            nitrogen=nitrogen,
            phosphorus=phosphorus,
            potassium=potassium,
            temperature_c=temp_c,
            humidity_percent=humidity,
            ph=ph,
            rainfall_mm=rainfall,
        )

        # For fertilizer recommendation, use predicted best crop if target crop is default or unspecified
        effective_crop = target_crop if (target_crop and target_crop.lower() != "general") else crop_result.get("recommended_crop", "Maize")

        # 4. Predict Fertilizer
        fertilizer_result = self.fertilizer_predictor.predict(
            temperature_c=temp_c,
            humidity_percent=humidity,
            moisture_percent=moisture,
            nitrogen=nitrogen,
            potassium=potassium,
            phosphorus=phosphorus,
            soil_type=soil_type,
            crop_type=effective_crop,
        )

        return {
            "timestamp": now.isoformat(),
            "telemetry_source": {
                "is_live_iot": has_live_sensors,
                "temperature_source": "ESP32_DHT11" if has_live_sensors else "DEFAULT",
                "humidity_source": "ESP32_DHT11" if has_live_sensors else "DEFAULT",
                "soil_moisture_source": "ESP32_CAPACITIVE" if has_live_sensors else "DEFAULT",
                "npk_source": "MANUAL_TEST_REPORT" if active_profile.get("is_manually_entered") else "HARDCODED_DEFAULT",
                "ph_source": "MANUAL_TEST_REPORT" if active_profile.get("is_manually_entered") else "HARDCODED_DEFAULT",
            },
            "environment": {
                "temperature_c": round(float(temp_c), 1),
                "humidity_percent": round(float(humidity), 1),
                "soil_moisture_estimate_percent": round(float(moisture), 1),
            },
            "soil_profile": {
                "nitrogen": round(nitrogen, 1),
                "phosphorus": round(phosphorus, 1),
                "potassium": round(potassium, 1),
                "ph": round(ph, 2),
                "rainfall_mm": round(rainfall, 1),
                "soil_type": soil_type,
                "target_crop": effective_crop,
                "is_manually_entered": active_profile.get("is_manually_entered", False),
            },
            "crop_recommendation": crop_result,
            "fertilizer_recommendation": fertilizer_result,
        }
