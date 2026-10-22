import os
from pathlib import Path
from dotenv import load_dotenv

# Locate base directories
BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent

# Load environment variables from .env if present
env_path = BASE_DIR / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
else:
    load_dotenv()


class Config:
    """Base application configuration."""

    FLASK_ENV = os.environ.get("FLASK_ENV", "development")
    DEBUG = FLASK_ENV == "development"
    HOST = os.environ.get("FLASK_HOST", "0.0.0.0")
    PORT = int(os.environ.get("FLASK_PORT", 5001))
    SECRET_KEY = os.environ.get("SECRET_KEY", "agrisense_secret_fallback_key")

    # Firebase
    FIREBASE_DATABASE_URL = os.environ.get(
        "FIREBASE_DATABASE_URL",
        "https://agrisense-ed6c9-default-rtdb.firebaseio.com/",
    )

    # Resolves path to service account key
    _raw_sa_path = os.environ.get(
        "FIREBASE_SERVICE_ACCOUNT",
        "backend/agrisense-ed6c9-firebase-adminsdk-fbsvc-8111f401b3.json",
    )
    if os.path.isabs(_raw_sa_path):
        FIREBASE_SERVICE_ACCOUNT = _raw_sa_path
    else:
        # Check relative to backend or project root
        p1 = PROJECT_ROOT / _raw_sa_path
        p2 = BASE_DIR / _raw_sa_path
        if p1.exists():
            FIREBASE_SERVICE_ACCOUNT = str(p1)
        elif p2.exists():
            FIREBASE_SERVICE_ACCOUNT = str(p2)
        else:
            FIREBASE_SERVICE_ACCOUNT = str(p1)

    # Device & Sensor Health Settings
    DEVICE_STALE_TIMEOUT_SECONDS = int(os.environ.get("DEVICE_STALE_TIMEOUT_SECONDS", 60))
    HISTORY_RETENTION_DAYS = int(os.environ.get("HISTORY_RETENTION_DAYS", 30))
    HISTORY_POLL_INTERVAL_SECONDS = int(os.environ.get("HISTORY_POLL_INTERVAL_SECONDS", 5))

    # Agronomic Fallback Thresholds (Soil moisture in %)
    SOIL_MOISTURE_CRITICAL_LOW = float(os.environ.get("SOIL_MOISTURE_CRITICAL_LOW", 25.0))
    SOIL_MOISTURE_OPTIMAL_MIN = float(os.environ.get("SOIL_MOISTURE_OPTIMAL_MIN", 40.0))
    SOIL_MOISTURE_OPTIMAL_MAX = float(os.environ.get("SOIL_MOISTURE_OPTIMAL_MAX", 75.0))
    SOIL_MOISTURE_CRITICAL_HIGH = float(os.environ.get("SOIL_MOISTURE_CRITICAL_HIGH", 85.0))

    # Temperature Thresholds (°C)
    TEMP_MIN = float(os.environ.get("TEMP_MIN", 10.0))
    TEMP_MAX = float(os.environ.get("TEMP_MAX", 38.0))

    # Humidity Thresholds (%)
    HUMIDITY_MIN = float(os.environ.get("HUMIDITY_MIN", 25.0))
    HUMIDITY_MAX = float(os.environ.get("HUMIDITY_MAX", 85.0))

    # ML Model Artifact Paths
    _raw_model_path = os.environ.get("MODEL_PATH", "backend/ml/models/irrigation_model.joblib")
    _raw_meta_path = os.environ.get("METADATA_PATH", "backend/ml/models/model_metadata.json")

    MODEL_PATH = str(PROJECT_ROOT / _raw_model_path) if not os.path.isabs(_raw_model_path) else _raw_model_path
    METADATA_PATH = str(PROJECT_ROOT / _raw_meta_path) if not os.path.isabs(_raw_meta_path) else _raw_meta_path

    # CORS Allowed Origins
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "*").split(",")
