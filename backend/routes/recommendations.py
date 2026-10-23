import logging
from flask import Blueprint, request, current_app
from backend.routes.utils import api_response

logger = logging.getLogger("agrisense.routes.recommendations")

recommendations_bp = Blueprint("recommendations", __name__)


def _get_live_reading():
    """Helper to retrieve and normalize live IoT telemetry."""
    firebase_svc = getattr(current_app, "firebase_service", None)
    sensor_svc = getattr(current_app, "sensor_service", None)
    if not firebase_svc or not sensor_svc:
        return None

    raw = firebase_svc.get_live_reading()
    if not raw:
        return None
    normalized, _ = sensor_svc.validate_and_normalize(raw)
    return normalized


@recommendations_bp.route("/recommendations/agronomy", methods=["GET"])
def get_agronomy_advisory():
    """
    Returns unified smart agriculture advisory:
    1. Best crop for the land (Kaggle ML model)
    2. Recommended fertilizer & dosage (Kaggle ML model)
    3. Live environmental metrics from ESP32 sensors (temp, humidity, soil moisture)
    4. Active NPK & pH soil profile
    """
    agronomy_svc = getattr(current_app, "agronomy_service", None)
    if not agronomy_svc:
        return api_response(
            data=None,
            success=False,
            error_code="SERVICE_UNAVAILABLE",
            error_message="Agronomy recommendation service is not initialized.",
            status_code=503,
        )

    live_reading = _get_live_reading()
    advisory = agronomy_svc.get_agronomy_advisory(live_telemetry=live_reading)
    return api_response(data=advisory, success=True)


@recommendations_bp.route("/recommendations/agronomy", methods=["POST"])
def run_custom_agronomy_advisory():
    """
    Runs agronomy advisory with optional farmer overrides for N, P, K, pH,
    soil_type, target_crop, rainfall, etc.
    """
    agronomy_svc = getattr(current_app, "agronomy_service", None)
    if not agronomy_svc:
        return api_response(
            data=None,
            success=False,
            error_code="SERVICE_UNAVAILABLE",
            error_message="Agronomy recommendation service is not initialized.",
            status_code=503,
        )

    body = request.get_json(silent=True) or {}
    live_reading = _get_live_reading()
    advisory = agronomy_svc.get_agronomy_advisory(live_telemetry=live_reading, overrides=body)
    return api_response(data=advisory, success=True)


@recommendations_bp.route("/recommendations/crop", methods=["POST"])
def predict_crop():
    """
    Executes Crop Recommendation ML Model.
    Accepts: {nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm}
    """
    crop_predictor = getattr(current_app, "crop_predictor", None)
    agronomy_svc = getattr(current_app, "agronomy_service", None)

    if not crop_predictor:
        return api_response(
            data=None,
            success=False,
            error_code="MODEL_UNAVAILABLE",
            error_message="Crop prediction model is not available.",
            status_code=503,
        )

    body = request.get_json(silent=True) or {}
    live = _get_live_reading()
    calibrated = (live or {}).get("calibrated", {})
    soil_profile = agronomy_svc.get_soil_profile() if agronomy_svc else {}

    n = float(body.get("nitrogen", soil_profile.get("nitrogen", 50.0)))
    p = float(body.get("phosphorus", soil_profile.get("phosphorus", 40.0)))
    k = float(body.get("potassium", soil_profile.get("potassium", 40.0)))
    ph = float(body.get("ph", soil_profile.get("ph", 6.5)))
    rain = float(body.get("rainfall_mm", soil_profile.get("rainfall_mm", 100.0)))

    temp = float(body.get("temperature_c", calibrated.get("temperature_c", 28.0)))
    hum = float(body.get("humidity_percent", calibrated.get("humidity_percent", 60.0)))
    moist_val = body.get("soil_moisture_estimate_percent", body.get("moisture_percent", calibrated.get("soil_moisture_estimate_percent")))
    moist = float(moist_val) if moist_val is not None else None

    # If rainfall not explicitly given, derive from soil moisture if available
    if "rainfall_mm" in body:
        rain = float(body["rainfall_mm"])
    elif soil_profile.get("is_manually_entered") and "rainfall_mm" in soil_profile:
        rain = float(soil_profile["rainfall_mm"])
    elif moist is not None:
        rain = 30.0 + (moist / 100.0) * 230.0
    else:
        rain = float(soil_profile.get("rainfall_mm", 100.0))

    result = crop_predictor.predict(
        nitrogen=n,
        phosphorus=p,
        potassium=k,
        temperature_c=temp,
        humidity_percent=hum,
        ph=ph,
        rainfall_mm=rain,
        soil_moisture_percent=moist,
    )
    return api_response(data=result, success=True)


@recommendations_bp.route("/recommendations/fertilizer", methods=["POST"])
def predict_fertilizer():
    """
    Executes Fertilizer Recommendation ML Model.
    Accepts: {temperature_c, humidity_percent, moisture_percent, nitrogen, potassium, phosphorus, soil_type, crop_type}
    """
    fertilizer_predictor = getattr(current_app, "fertilizer_predictor", None)
    agronomy_svc = getattr(current_app, "agronomy_service", None)

    if not fertilizer_predictor:
        return api_response(
            data=None,
            success=False,
            error_code="MODEL_UNAVAILABLE",
            error_message="Fertilizer prediction model is not available.",
            status_code=503,
        )

    body = request.get_json(silent=True) or {}
    live = _get_live_reading()
    calibrated = (live or {}).get("calibrated", {})
    soil_profile = agronomy_svc.get_soil_profile() if agronomy_svc else {}

    temp = float(body.get("temperature_c", calibrated.get("temperature_c", 28.0)))
    hum = float(body.get("humidity_percent", calibrated.get("humidity_percent", 60.0)))
    moist = float(body.get("moisture_percent", calibrated.get("soil_moisture_estimate_percent", 40.0)))

    n = float(body.get("nitrogen", soil_profile.get("nitrogen", 50.0)))
    p = float(body.get("phosphorus", soil_profile.get("phosphorus", 40.0)))
    k = float(body.get("potassium", soil_profile.get("potassium", 40.0)))
    soil = str(body.get("soil_type", soil_profile.get("soil_type", "Loamy")))
    crop = str(body.get("crop_type", soil_profile.get("target_crop", "Maize")))

    result = fertilizer_predictor.predict(
        temperature_c=temp,
        humidity_percent=hum,
        moisture_percent=moist,
        nitrogen=n,
        potassium=k,
        phosphorus=p,
        soil_type=soil,
        crop_type=crop,
    )
    return api_response(data=result, success=True)


@recommendations_bp.route("/recommendations/soil-profile", methods=["GET"])
def get_soil_profile():
    """Returns active soil test parameters."""
    agronomy_svc = getattr(current_app, "agronomy_service", None)
    if not agronomy_svc:
        return api_response(data=None, success=False, error_code="SERVICE_UNAVAILABLE", error_message="Agronomy service not ready.", status_code=503)

    return api_response(data=agronomy_svc.get_soil_profile(), success=True)


@recommendations_bp.route("/recommendations/soil-profile", methods=["POST"])
def update_soil_profile():
    """Allows farmer to submit or update their soil test report (NPK, pH, soil type)."""
    agronomy_svc = getattr(current_app, "agronomy_service", None)
    if not agronomy_svc:
        return api_response(data=None, success=False, error_code="SERVICE_UNAVAILABLE", error_message="Agronomy service not ready.", status_code=503)

    body = request.get_json(silent=True) or {}
    updated = agronomy_svc.update_soil_profile(body)
    return api_response(data=updated, success=True)


@recommendations_bp.route("/recommendations/soil-profile", methods=["DELETE"])
def reset_soil_profile():
    """Resets soil profile back to hardcoded baseline defaults."""
    agronomy_svc = getattr(current_app, "agronomy_service", None)
    if not agronomy_svc:
        return api_response(data=None, success=False, error_code="SERVICE_UNAVAILABLE", error_message="Agronomy service not ready.", status_code=503)

    reset_val = agronomy_svc.reset_soil_profile()
    return api_response(data=reset_val, success=True)
