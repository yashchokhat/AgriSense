import pytest
from datetime import datetime, timezone
from unittest.mock import MagicMock
from backend.app import create_app
from backend.config import Config
from backend.services.sensor_service import SensorService
from backend.services.history_service import HistoryService
from backend.services.recommendation_service import RecommendationService
from backend.services.alert_service import AlertService
from backend.ml.predict import IrrigationPredictor

class TestConfig(Config):
    TESTING = True
    FLASK_ENV = "testing"
    DEVICE_STALE_TIMEOUT_SECONDS = 10
    SOIL_MOISTURE_CRITICAL_LOW = 25.0
    SOIL_MOISTURE_OPTIMAL_MIN = 40.0
    SOIL_MOISTURE_OPTIMAL_MAX = 75.0
    SOIL_MOISTURE_CRITICAL_HIGH = 85.0

@pytest.fixture
def sample_raw_reading():
    return {
        "dht_valid": True,
        "temperature_c": 28.5,
        "humidity_percent": 62.0,
        "soil_ao_raw": 3200,
        "soil_do": 1,
        "soil_status": "DRY",
        "soil_adc_range_percent": 100,
        "soil_moisture_estimate_percent": 33.2,
        "wifi_rssi_dbm": -72,
        "uptime_ms": 120500,
    }

@pytest.fixture
def mock_firebase_service(sample_raw_reading):
    mock = MagicMock()
    mock.is_initialized = True
    mock.database_url = "https://mock-agrisense.firebaseio.com/"
    mock.get_status.return_value = {
        "initialized": True,
        "database_url": "https://mock-agrisense.firebaseio.com/",
        "error": None,
    }
    mock.get_live_reading.return_value = sample_raw_reading
    mock.save_history_point.return_value = True
    mock.get_history.return_value = []
    return mock

@pytest.fixture
def app(mock_firebase_service):
    app = create_app(TestConfig)
    # Replace live firebase with mock
    app.firebase_service = mock_firebase_service
    app.history_service.firebase = mock_firebase_service
    return app

@pytest.fixture
def client(app):
    return app.test_client()
