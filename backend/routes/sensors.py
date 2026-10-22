from flask import Blueprint, current_app, request
from backend.routes.utils import api_response

sensors_bp = Blueprint("sensors", __name__)

@sensors_bp.route("/sensors/latest", methods=["GET"])
def get_latest_sensor_reading():
    """Fetches the latest validated sensor reading from Firebase."""
    firebase_svc = current_app.firebase_service
    sensor_svc = current_app.sensor_service
    history_svc = current_app.history_service

    raw_data = firebase_svc.get_live_reading() if firebase_svc else None
    if not raw_data:
        return api_response(
            data=None,
            success=False,
            error_code="NO_DATA",
            error_message="No sensor telemetry currently available from device.",
            status_code=404,
        )

    normalized, warnings = sensor_svc.validate_and_normalize(raw_data)
    if not normalized:
        return api_response(
            data=None,
            success=False,
            error_code="VALIDATION_FAILED",
            error_message="Sensor telemetry failed integrity validation.",
            error_details=warnings,
            status_code=422,
        )

    # Ingest new reading into history deduplicating automatically
    if history_svc:
        history_svc.ingest_reading(normalized)

    return api_response(data=normalized, success=True)

@sensors_bp.route("/sensors/history", methods=["GET"])
def get_sensor_history():
    """
    Returns time-bounded historical sensor readings and statistical summaries.
    Query parameters:
      - hours (float, default 24.0, max 720)
      - limit (int, default 100, max 500)
    """
    history_svc = current_app.history_service

    # Validate hours query param
    hours_arg = request.args.get("hours", "24")
    try:
        hours = float(hours_arg)
        if hours <= 0 or hours > 720:
            return api_response(
                data=None,
                success=False,
                error_code="INVALID_PARAMETER",
                error_message="The 'hours' parameter must be between 0.1 and 720 (30 days).",
                status_code=400,
            )
    except ValueError:
        return api_response(
            data=None,
            success=False,
            error_code="INVALID_PARAMETER",
            error_message="The 'hours' parameter must be a valid number.",
            status_code=400,
        )

    # Validate limit query param
    limit_arg = request.args.get("limit", "100")
    try:
        limit = int(limit_arg)
        if limit <= 0 or limit > 500:
            return api_response(
                data=None,
                success=False,
                error_code="INVALID_PARAMETER",
                error_message="The 'limit' parameter must be between 1 and 500.",
                status_code=400,
            )
    except ValueError:
        return api_response(
            data=None,
            success=False,
            error_code="INVALID_PARAMETER",
            error_message="The 'limit' parameter must be an integer.",
            status_code=400,
        )

    history_data = history_svc.get_history(hours=hours, limit=limit)
    return api_response(data=history_data, success=True)
