import pytest
from datetime import datetime, timezone
from backend.services.history_service import HistoryService
from backend.services.sensor_service import SensorService

def test_history_deduplication(mock_firebase_service, sample_raw_reading):
    sensor_svc = SensorService()
    history_svc = HistoryService(firebase_service=mock_firebase_service)

    normalized, _ = sensor_svc.validate_and_normalize(sample_raw_reading)

    # First ingest should succeed
    res1 = history_svc.ingest_reading(normalized)
    assert res1 is True
    assert len(history_svc._local_history) == 1

    # Ingesting the identical reading (same uptime_ms) must be dropped
    res2 = history_svc.ingest_reading(normalized)
    assert res2 is False
    assert len(history_svc._local_history) == 1

def test_history_query_and_statistics(mock_firebase_service):
    history_svc = HistoryService(firebase_service=mock_firebase_service)

    # Mock historical records
    history_svc._local_history = [
        {
            "id": "1",
            "timestamp": "2026-10-23T01:00:00Z",
            "timestamp_ms": int(datetime.now(timezone.utc).timestamp() * 1000) - 3600000,
            "temperature_c": 24.0,
            "humidity_percent": 60.0,
            "soil_moisture_estimate_percent": 40.0,
            "uptime_ms": 1000,
            "valid": True,
        },
        {
            "id": "2",
            "timestamp": "2026-10-23T02:00:00Z",
            "timestamp_ms": int(datetime.now(timezone.utc).timestamp() * 1000) - 1800000,
            "temperature_c": 28.0,
            "humidity_percent": 50.0,
            "soil_moisture_estimate_percent": 30.0,
            "uptime_ms": 2000,
            "valid": True,
        },
    ]

    res = history_svc.get_history(hours=24.0, limit=10)
    summary = res["summary"]

    assert summary["count"] == 2
    assert summary["temperature"]["min"] == 24.0
    assert summary["temperature"]["max"] == 28.0
    assert summary["temperature"]["avg"] == 26.0
    assert summary["soil_moisture"]["min"] == 30.0
    assert summary["soil_moisture"]["max"] == 40.0
    assert summary["soil_moisture"]["avg"] == 35.0
