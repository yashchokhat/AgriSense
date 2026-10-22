from flask import Blueprint, current_app, request
from backend.routes.utils import api_response

predictions_bp = Blueprint("predictions", __name__)

@predictions_bp.route("/predictions/latest", methods=["GET"])
def get_latest_prediction():
    """Returns the latest irrigation recommendation and ML prediction status."""
    firebase_svc = current_app.firebase_service
    sensor_svc = current_app.sensor_service
    rec_svc = current_app.recommendation_service

    crop_type = request.args.get("crop_type", current_app.config.get("DEFAULT_CROP", "general"))
    soil_type = request.args.get("soil_type", current_app.config.get("DEFAULT_SOIL", "loam"))

    # Fetch live reading
    raw_data = firebase_svc.get_live_reading() if firebase_svc else None
    normalized, _ = sensor_svc.validate_and_normalize(raw_data) if raw_data else (None, [])

    prediction = rec_svc.get_recommendation(
        normalized_reading=normalized,
        crop_type=crop_type,
        soil_type=soil_type,
    )

    return api_response(data=prediction, success=True)

@predictions_bp.route("/predictions/run", methods=["POST"])
def run_prediction():
    """
    Triggers an immediate prediction inference run.
    Body JSON may specify:
      - crop_type (string, optional)
      - soil_type (string, optional)
      - force_rule_based (bool, optional)
    """
    firebase_svc = current_app.firebase_service
    sensor_svc = current_app.sensor_service
    rec_svc = current_app.recommendation_service

    body = request.get_json(silent=True) or {}
    crop_type = body.get("crop_type", current_app.config.get("DEFAULT_CROP", "general"))
    soil_type = body.get("soil_type", current_app.config.get("DEFAULT_SOIL", "loam"))
    force_rule = bool(body.get("force_rule_based", False))

    raw_data = firebase_svc.get_live_reading() if firebase_svc else None
    if not raw_data:
        return api_response(
            data=None,
            success=False,
            error_code="NO_SENSOR_DATA",
            error_message="Cannot run prediction: No sensor reading available from device.",
            status_code=400,
        )

    normalized, warnings = sensor_svc.validate_and_normalize(raw_data)
    if not normalized or not normalized["quality"]["all_valid"]:
        return api_response(
            data=None,
            success=False,
            error_code="INVALID_SENSOR_DATA",
            error_message="Sensor telemetry is invalid or corrupted. Prediction rejected for safety.",
            error_details=warnings,
            status_code=422,
        )

    result = rec_svc.get_recommendation(
        normalized_reading=normalized,
        crop_type=crop_type,
        soil_type=soil_type,
        force_rule_based=force_rule,
    )

    # Optionally persist latest prediction to Firebase
    if firebase_svc and result.get("available"):
        firebase_svc.save_prediction(result)

    return api_response(data=result, success=True)
