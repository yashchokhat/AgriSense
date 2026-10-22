from flask import Blueprint, current_app, request
from backend.routes.utils import api_response

alerts_bp = Blueprint("alerts", __name__)

@alerts_bp.route("/alerts", methods=["GET"])
def get_alerts():
    """Returns active and recent alerts evaluated against live telemetry."""
    firebase_svc = current_app.firebase_service
    sensor_svc = current_app.sensor_service
    alert_svc = current_app.alert_service

    raw_data = firebase_svc.get_live_reading() if firebase_svc else None
    normalized = None
    if raw_data:
        normalized, _ = sensor_svc.validate_and_normalize(raw_data)

    active_alerts = alert_svc.evaluate_alerts(normalized)

    # Summary counts
    counts = {
        "total": len(active_alerts),
        "critical": sum(1 for a in active_alerts if a["severity"] == "CRITICAL"),
        "warning": sum(1 for a in active_alerts if a["severity"] == "WARNING"),
        "info": sum(1 for a in active_alerts if a["severity"] == "INFO"),
        "error": sum(1 for a in active_alerts if a["severity"] == "ERROR"),
    }

    return api_response(
        data={
            "summary": counts,
            "alerts": active_alerts,
        },
        success=True,
    )
