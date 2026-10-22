from flask import Blueprint, current_app, request
from backend.routes.utils import api_response

dashboard_bp = Blueprint("dashboard", __name__)

@dashboard_bp.route("/dashboard", methods=["GET"])
def get_dashboard_summary():
    """
    Consolidated dashboard payload returning live sensor readings, device connectivity,
    active alerts, current recommendation/ML prediction, and historical trends summary.
    """
    firebase_svc = current_app.firebase_service
    sensor_svc = current_app.sensor_service
    rec_svc = current_app.recommendation_service
    alert_svc = current_app.alert_service
    history_svc = current_app.history_service

    crop_type = request.args.get("crop_type", current_app.config.get("DEFAULT_CROP", "general"))
    soil_type = request.args.get("soil_type", current_app.config.get("DEFAULT_SOIL", "loam"))

    # 1. Fetch live reading
    raw_data = firebase_svc.get_live_reading() if firebase_svc else None
    normalized = None
    if raw_data:
        normalized, _ = sensor_svc.validate_and_normalize(raw_data)
        if normalized and history_svc:
            history_svc.ingest_reading(normalized)

    # 2. Alerts
    active_alerts = alert_svc.evaluate_alerts(normalized)

    # 3. Prediction / Recommendation
    recommendation = rec_svc.get_recommendation(
        normalized_reading=normalized,
        crop_type=crop_type,
        soil_type=soil_type,
    )

    # 4. 24-hour summary stats
    history_summary = history_svc.get_history(hours=24, limit=20)["summary"] if history_svc else None

    # Construct complete dashboard model
    dashboard_data = {
        "device": {
            "device_id": "ESP32_AGRISENSE_01",
            "is_online": normalized["device_health"]["is_online"] if normalized else False,
            "is_stale": normalized["device_health"]["is_stale"] if normalized else True,
            "last_seen_timestamp": normalized["device_health"]["last_seen_timestamp"] if normalized else None,
            "seconds_since_last_seen": normalized["device_health"]["seconds_since_last_seen"] if normalized else None,
            "wifi_rssi_dbm": normalized["raw"]["wifi_rssi_dbm"] if normalized else None,
            "wifi_quality": normalized["device_health"]["wifi_quality"] if normalized else "UNKNOWN",
            "uptime_ms": normalized["uptime_ms"] if normalized else 0,
        },
        "telemetry": {
            "has_data": normalized is not None,
            "timestamp": normalized["timestamp"] if normalized else None,
            "calibrated": normalized["calibrated"] if normalized else {
                "temperature_c": None,
                "humidity_percent": None,
                "soil_moisture_estimate_percent": None,
            },
            "raw": normalized["raw"] if normalized else {
                "soil_ao_raw": None,
                "soil_do": None,
                "soil_adc_range_percent": None,
                "wifi_rssi_dbm": None,
            },
            "units": normalized["units"] if normalized else {
                "temperature": "°C",
                "humidity": "%",
                "soil_moisture_estimate": "%",
                "soil_ao_raw": "ADC (12-bit)",
            },
            "threshold_status": normalized["threshold_status"] if normalized else {
                "soil_status": "UNKNOWN",
                "soil_do_threshold_active": False,
            },
            "quality": normalized["quality"] if normalized else {
                "dht_valid": False,
                "soil_valid": False,
                "all_valid": False,
                "warnings": ["Device offline or no telemetry."],
            },
        },
        "recommendation": recommendation,
        "alerts_summary": {
            "count": len(active_alerts),
            "critical_count": sum(1 for a in active_alerts if a["severity"] == "CRITICAL"),
            "items": active_alerts[:5],  # top 5 most recent
        },
        "trends_24h": history_summary,
    }

    return api_response(data=dashboard_data, success=True)
