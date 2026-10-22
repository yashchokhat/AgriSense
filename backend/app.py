import os
import sys
import logging
from pathlib import Path

# Ensure project root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from flask import Flask, jsonify
from flask_cors import CORS

from backend.config import Config
from backend.services.firebase_service import FirebaseService
from backend.services.sensor_service import SensorService
from backend.services.history_service import HistoryService
from backend.services.recommendation_service import RecommendationService
from backend.services.alert_service import AlertService
from backend.ml.predict import IrrigationPredictor
from backend.routes.utils import api_response

from backend.routes.health import health_bp
from backend.routes.dashboard import dashboard_bp
from backend.routes.sensors import sensors_bp
from backend.routes.predictions import predictions_bp
from backend.routes.alerts import alerts_bp
from backend.routes.settings import settings_bp

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("agrisense.app")

def create_app(config_class=Config) -> Flask:
    """Application factory for AgriSense REST API backend."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Enable Cross-Origin Resource Sharing (CORS)
    CORS(app, resources={r"/api/*": {"origins": app.config.get("CORS_ORIGINS", "*")}})

    # 1. Initialize Firebase Service
    firebase_svc = FirebaseService(
        database_url=app.config["FIREBASE_DATABASE_URL"],
        credential_path=app.config["FIREBASE_SERVICE_ACCOUNT"],
    )
    app.firebase_service = firebase_svc

    # 2. Initialize Sensor Quality & Validation Service
    sensor_svc = SensorService(
        stale_timeout_seconds=app.config["DEVICE_STALE_TIMEOUT_SECONDS"]
    )
    app.sensor_service = sensor_svc

    # 3. Initialize History Service
    history_svc = HistoryService(firebase_service=firebase_svc)
    app.history_service = history_svc

    # 4. Initialize ML Predictor
    ml_predictor = IrrigationPredictor(
        model_path=app.config["MODEL_PATH"],
        metadata_path=app.config["METADATA_PATH"],
    )
    app.ml_predictor = ml_predictor

    # 5. Initialize Recommendation Service
    rec_svc = RecommendationService(
        predictor=ml_predictor,
        critical_low_threshold=app.config["SOIL_MOISTURE_CRITICAL_LOW"],
        optimal_min_threshold=app.config["SOIL_MOISTURE_OPTIMAL_MIN"],
        optimal_max_threshold=app.config["SOIL_MOISTURE_OPTIMAL_MAX"],
        critical_high_threshold=app.config["SOIL_MOISTURE_CRITICAL_HIGH"],
    )
    app.recommendation_service = rec_svc

    # 6. Initialize Alert Service
    alert_svc = AlertService(
        temp_min=app.config["TEMP_MIN"],
        temp_max=app.config["TEMP_MAX"],
        humidity_min=app.config["HUMIDITY_MIN"],
        humidity_max=app.config["HUMIDITY_MAX"],
        soil_critical_low=app.config["SOIL_MOISTURE_CRITICAL_LOW"],
        soil_critical_high=app.config["SOIL_MOISTURE_CRITICAL_HIGH"],
    )
    app.alert_service = alert_svc

    # Register Blueprints under /api/v1 prefix
    api_prefix = "/api/v1"
    app.register_blueprint(health_bp, url_prefix=api_prefix)
    app.register_blueprint(dashboard_bp, url_prefix=api_prefix)
    app.register_blueprint(sensors_bp, url_prefix=api_prefix)
    app.register_blueprint(predictions_bp, url_prefix=api_prefix)
    app.register_blueprint(alerts_bp, url_prefix=api_prefix)
    app.register_blueprint(settings_bp, url_prefix=api_prefix)

    # Root redirect / index
    @app.route("/", methods=["GET"])
    def index():
        return api_response(
            data={
                "name": "AgriSense REST API",
                "version": "1.0.0",
                "documentation": "/api/v1/health",
            },
            success=True,
        )

    # Centralized HTTP error handlers
    @app.errorhandler(404)
    def not_found(e):
        return api_response(
            data=None,
            success=False,
            error_code="NOT_FOUND",
            error_message="The requested endpoint does not exist.",
            status_code=404,
        )

    @app.errorhandler(405)
    def method_not_allowed(e):
        return api_response(
            data=None,
            success=False,
            error_code="METHOD_NOT_ALLOWED",
            error_message="HTTP method not allowed for this endpoint.",
            status_code=405,
        )

    @app.errorhandler(500)
    def server_error(e):
        logger.error("Internal server error: %s", e)
        return api_response(
            data=None,
            success=False,
            error_code="INTERNAL_SERVER_ERROR",
            error_message="An internal server error occurred.",
            status_code=500,
        )

    return app

# WSGI Application instance
app = create_app()

if __name__ == "__main__":
    host = app.config.get("HOST", "0.0.0.0")
    port = app.config.get("PORT", 5001)
    debug = app.config.get("DEBUG", False)
    logger.info("Starting AgriSense API server on %s:%s (debug=%s)", host, port, debug)
    app.run(host=host, port=port, debug=debug)
