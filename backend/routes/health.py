from flask import Blueprint, current_app
from backend.routes.utils import api_response

health_bp = Blueprint("health", __name__)

@health_bp.route("/health", methods=["GET"])
def get_health():
    """
    Returns API health status, Firebase connection status, and ML model availability.
    Never exposes internal secrets or file paths.
    """
    firebase_svc = current_app.firebase_service
    predictor = current_app.ml_predictor

    firebase_status = firebase_svc.get_status() if firebase_svc else {"initialized": False}
    ml_status = {
        "loaded": predictor.is_loaded if predictor else False,
        "model_version": predictor.metadata.get("model_version") if predictor else None,
    }

    all_ok = firebase_status.get("initialized", False) and ml_status.get("loaded", False)

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
        },
    }

    status_code = 200 if all_ok else 207
    return api_response(data=health_data, success=True, status_code=status_code)
