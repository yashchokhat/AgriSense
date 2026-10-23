from flask import Blueprint, current_app
from backend.routes.utils import api_response

health_bp = Blueprint("health", __name__)

@health_bp.route("/health", methods=["GET"])
def get_health():
    """
    Returns API health status, Firebase connection status, and ML model availability.
    Never exposes internal secrets or file paths.
    """
    firebase_svc = getattr(current_app, "firebase_service", None)
    predictor = getattr(current_app, "ml_predictor", None)
    crop_predictor = getattr(current_app, "crop_predictor", None)
    fertilizer_predictor = getattr(current_app, "fertilizer_predictor", None)

    firebase_status = firebase_svc.get_status() if firebase_svc else {"initialized": False}
    ml_status = {
        "loaded": predictor.is_loaded if predictor else False,
        "model_version": predictor.metadata.get("model_version") if predictor else None,
    }

    all_ok = (
        firebase_status.get("initialized", False)
        and ml_status.get("loaded", False)
        and (crop_predictor.is_loaded if crop_predictor else False)
        and (fertilizer_predictor.is_loaded if fertilizer_predictor else False)
    )

    health_data = {
        "status": "healthy" if all_ok else "degraded",
        "api_version": "1.0.0",
        "services": {
            "firebase": {
                "connected": firebase_status.get("initialized", False),
                "rtdb_target": "configured" if firebase_status.get("database_url") else "missing",
            },
            "ml_engine": {
                "available": ml_status["loaded"],
                "model_version": ml_status["model_version"],
            },
            "crop_engine": {
                "available": crop_predictor.is_loaded if crop_predictor else False,
                "model": "RandomForest (Kaggle Crop Recommendation)",
            },
            "fertilizer_engine": {
                "available": fertilizer_predictor.is_loaded if fertilizer_predictor else False,
                "model": "RandomForest Pipeline (Kaggle Fertilizer Prediction)",
            },
        },
    }

    status_code = 200 if all_ok else 207
    return api_response(data=health_data, success=True, status_code=status_code)
