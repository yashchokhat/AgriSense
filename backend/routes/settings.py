from flask import Blueprint, current_app, request
from backend.routes.utils import api_response
from backend.ml.features import CROP_TYPE_MAPPING, SOIL_TYPE_MAPPING

settings_bp = Blueprint("settings", __name__)

@settings_bp.route("/config", methods=["GET"])
def get_config():
    """Returns accessible application configuration and selectable options."""
    cfg = current_app.config

    config_data = {
        "device": {
            "device_id": "ESP32_AGRISENSE_01",
            "stale_timeout_seconds": cfg.get("DEVICE_STALE_TIMEOUT_SECONDS", 60),
            "refresh_interval_seconds": 3,
            "background_refresh_seconds": 30,
        },
        "thresholds": {
            "soil_moisture_critical_low": cfg.get("SOIL_MOISTURE_CRITICAL_LOW", 25.0),
            "soil_moisture_optimal_min": cfg.get("SOIL_MOISTURE_OPTIMAL_MIN", 40.0),
            "soil_moisture_optimal_max": cfg.get("SOIL_MOISTURE_OPTIMAL_MAX", 75.0),
            "soil_moisture_critical_high": cfg.get("SOIL_MOISTURE_CRITICAL_HIGH", 85.0),
            "temperature_min_c": cfg.get("TEMP_MIN", 10.0),
            "temperature_max_c": cfg.get("TEMP_MAX", 38.0),
            "humidity_min_percent": cfg.get("HUMIDITY_MIN", 25.0),
            "humidity_max_percent": cfg.get("HUMIDITY_MAX", 85.0),
        },
        "options": {
            "supported_crops": list(CROP_TYPE_MAPPING.keys()),
            "supported_soils": list(SOIL_TYPE_MAPPING.keys()),
        },
    }

    return api_response(data=config_data, success=True)

@settings_bp.route("/config", methods=["POST"])
def update_config():
    """Allows authenticated update of operational thresholds."""
    body = request.get_json(silent=True) or {}
    cfg = current_app.config

    thresholds = body.get("thresholds", {})
    updated = {}

    if "soil_moisture_critical_low" in thresholds:
        val = float(thresholds["soil_moisture_critical_low"])
        cfg["SOIL_MOISTURE_CRITICAL_LOW"] = val
        current_app.recommendation_service.critical_low_threshold = val
        current_app.alert_service.soil_critical_low = val
        updated["soil_moisture_critical_low"] = val

    if "soil_moisture_optimal_min" in thresholds:
        val = float(thresholds["soil_moisture_optimal_min"])
        cfg["SOIL_MOISTURE_OPTIMAL_MIN"] = val
        current_app.recommendation_service.optimal_min_threshold = val
        updated["soil_moisture_optimal_min"] = val

    if "soil_moisture_optimal_max" in thresholds:
        val = float(thresholds["soil_moisture_optimal_max"])
        cfg["SOIL_MOISTURE_OPTIMAL_MAX"] = val
        current_app.recommendation_service.optimal_max_threshold = val
        updated["soil_moisture_optimal_max"] = val

    return api_response(
        data={"updated": updated},
        success=True,
    )
