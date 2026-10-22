import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from backend.ml.predict import IrrigationPredictor

logger = logging.getLogger("agrisense.recommendation")

class RecommendationService:
    """Provides smart irrigation recommendations using ML inference or rule-based fallbacks."""

    def __init__(
        self,
        predictor: IrrigationPredictor,
        critical_low_threshold: float = 25.0,
        optimal_min_threshold: float = 40.0,
        optimal_max_threshold: float = 75.0,
        critical_high_threshold: float = 85.0,
    ):
        self.predictor = predictor
        self.critical_low_threshold = critical_low_threshold
        self.optimal_min_threshold = optimal_min_threshold
        self.optimal_max_threshold = optimal_max_threshold
        self.critical_high_threshold = critical_high_threshold

    def get_recommendation(
        self,
        normalized_reading: Optional[Dict[str, Any]],
        crop_type: str = "general",
        soil_type: str = "loam",
        force_rule_based: bool = False,
    ) -> Dict[str, Any]:
        """
        Generates irrigation recommendation.
        Uses trained ML model if loaded and reading is valid.
        Falls back to rule-based analysis otherwise, with explicit labelling.
        """
        now = datetime.now(timezone.utc)

        if not normalized_reading:
            return {
                "available": False,
                "recommendation_type": "none",
                "irrigation_needed": None,
                "urgency": "UNKNOWN",
                "confidence": None,
                "is_ml_based": False,
                "model_version": None,
                "title": "Sensor Data Unavailable",
                "message": "No sensor readings are available to assess irrigation requirements.",
                "explanation": ["Awaiting sensor data ingestion."],
                "timestamp": now.isoformat(),
            }

        quality = normalized_reading.get("quality", {})
        calibrated = normalized_reading.get("calibrated", {})
        moisture = calibrated.get("soil_moisture_estimate_percent")
        temp = calibrated.get("temperature_c")
        humidity = calibrated.get("humidity_percent")

        # Check if sensor data is valid
        if not quality.get("all_valid", False) and moisture is None:
            return {
                "available": False,
                "recommendation_type": "sensor_error",
                "irrigation_needed": None,
                "urgency": "ERROR",
                "confidence": None,
                "is_ml_based": False,
                "model_version": None,
                "title": "Sensor Error Detected",
                "message": "Sensor reading failed quality validation checks. Irrigation cannot be safely estimated.",
                "explanation": quality.get("warnings", ["Sensor read error."]),
                "timestamp": now.isoformat(),
            }

        # If ML model is loaded and not forced to rule-based:
        if self.predictor.is_loaded and not force_rule_based:
            ml_result = self.predictor.predict(
                reading=normalized_reading,
                crop_type=crop_type,
                soil_type=soil_type,
            )

            if ml_result.get("available", False):
                needed = ml_result["irrigation_needed"]
                urgency = "HIGH" if (needed and (moisture is not None and moisture < self.critical_low_threshold)) else ("MODERATE" if needed else "LOW")
                title = "Irrigation Recommended (ML)" if needed else "No Irrigation Required (ML)"
                message = (
                    f"Machine learning model predicts active moisture deficit for {crop_type} in {soil_type} soil."
                    if needed
                    else f"Soil moisture and atmospheric conditions are optimal for {crop_type}."
                )

                return {
                    "available": True,
                    "recommendation_type": "ml_prediction",
                    "irrigation_needed": needed,
                    "urgency": urgency,
                    "confidence": ml_result.get("confidence"),
                    "is_ml_based": True,
                    "model_version": ml_result.get("model_version"),
                    "title": title,
                    "message": message,
                    "explanation": ml_result.get("explanation", []),
                    "features_used": ml_result.get("features_used", {}),
                    "timestamp": now.isoformat(),
                }

        # Fallback to Agronomic Rule Engine
        return self._rule_based_recommendation(
            normalized_reading=normalized_reading,
            crop_type=crop_type,
            soil_type=soil_type,
            now=now,
        )

    def _rule_based_recommendation(
        self,
        normalized_reading: Dict[str, Any],
        crop_type: str,
        soil_type: str,
        now: datetime,
    ) -> Dict[str, Any]:
        calibrated = normalized_reading.get("calibrated", {})
        threshold_status = normalized_reading.get("threshold_status", {})
        raw = normalized_reading.get("raw", {})

        moisture = calibrated.get("soil_moisture_estimate_percent", 0.0)
        temp = calibrated.get("temperature_c")
        soil_status = threshold_status.get("soil_status", "UNKNOWN")
        do_active = threshold_status.get("soil_do_threshold_active", False)

        explanations = []
        is_needed = False
        urgency = "LOW"
        title = "Optimal Moisture Level"
        message = f"Soil moisture is adequate ({moisture}%) for {crop_type}."

        if moisture < self.critical_low_threshold or soil_status == "DRY":
            is_needed = True
            urgency = "CRITICAL"
            title = "Irrigation Urgently Required (Rule-Based)"
            message = f"Soil moisture ({moisture}%) is critically low below threshold ({self.critical_low_threshold}%)."
            explanations.append(
                f"Calibrated soil moisture estimate ({moisture}%) is below the critical wilt threshold of {self.critical_low_threshold}%."
            )
            explanations.append(
                f"Hardware digital sensor state confirms dryness (DO={raw.get('soil_do')}, status={soil_status})."
            )
        elif moisture < self.optimal_min_threshold:
            is_needed = True
            urgency = "MODERATE"
            title = "Irrigation Recommended Soon (Rule-Based)"
            message = f"Moisture ({moisture}%) is approaching depletion point ({self.optimal_min_threshold}%)."
            explanations.append(
                f"Soil moisture ({moisture}%) has dipped below the optimal range minimum of {self.optimal_min_threshold}%."
            )
        elif moisture > self.critical_high_threshold or soil_status == "WET":
            is_needed = False
            urgency = "WARNING"
            title = "Soil Saturated / Excess Water (Rule-Based)"
            message = f"Soil moisture ({moisture}%) is excessively high. Risk of root waterlogging."
            explanations.append(
                f"Soil moisture ({moisture}%) exceeds saturation threshold ({self.critical_high_threshold}%). Cease irrigation."
            )
        else:
            is_needed = False
            urgency = "LOW"
            title = "Soil Moisture Optimal (Rule-Based)"
            message = f"Moisture ({moisture}%) is in ideal vegetative range ({self.optimal_min_threshold}% - {self.optimal_max_threshold}%)."
            explanations.append(
                f"Moisture is stable within the target agronomic window for {soil_type} soil."
            )

        if temp and temp > 32.0 and is_needed:
            explanations.append(f"High ambient temperature ({temp}°C) will exacerbate crop stress; schedule watering early or late in the day.")

        return {
            "available": True,
            "recommendation_type": "threshold_rule",
            "irrigation_needed": is_needed,
            "urgency": urgency,
            "confidence": None,  # Rules do not invent ML confidence
            "is_ml_based": False,
            "model_version": "agronomic-rules-v1",
            "title": title,
            "message": message,
            "explanation": explanations,
            "timestamp": now.isoformat(),
        }
