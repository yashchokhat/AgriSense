import pytest
from datetime import datetime, timezone, timedelta
from backend.services.sensor_service import SensorService

def test_sensor_service_valid_reading(sample_raw_reading):
    svc = SensorService(stale_timeout_seconds=60)
    normalized, warnings = svc.validate_and_normalize(sample_raw_reading)

    assert normalized is not None
    assert normalized["quality"]["all_valid"] is True
    assert normalized["calibrated"]["temperature_c"] == 28.5
    assert normalized["calibrated"]["humidity_percent"] == 62.0
    assert normalized["calibrated"]["soil_moisture_estimate_percent"] == 33.2
    assert normalized["raw"]["soil_ao_raw"] == 3200
    assert normalized["raw"]["soil_do"] == 1
    assert normalized["threshold_status"]["soil_status"] == "DRY"
    assert normalized["device_health"]["is_online"] is True
    assert normalized["device_health"]["is_stale"] is False

def test_sensor_service_invalid_and_out_of_bounds():
    svc = SensorService(stale_timeout_seconds=60)
    bad_payload = {
        "temperature_c": 120.0,  # Physically implausible for DHT11
        "humidity_percent": -5.0, # Negative humidity
        "soil_ao_raw": 50000,    # Outside 12-bit ADC (0-4095)
        "uptime_ms": -100,
        "dht_valid": False,
    }

    normalized, warnings = svc.validate_and_normalize(bad_payload)
    assert normalized is not None
    assert normalized["quality"]["all_valid"] is False
    assert normalized["quality"]["dht_valid"] is False
    assert normalized["quality"]["soil_valid"] is False
    assert len(warnings) >= 3

def test_sensor_service_none_payload():
    svc = SensorService(stale_timeout_seconds=60)
    normalized, warnings = svc.validate_and_normalize(None)
    assert normalized is None
    assert "No sensor data" in warnings[0]

def test_sensor_service_staleness():
    svc = SensorService(stale_timeout_seconds=10)
    t0 = datetime(2026, 10, 23, 10, 0, 0, tzinfo=timezone.utc)
    t1 = t0 + timedelta(seconds=15) # 15s later, above 10s threshold

    reading = {
        "temperature_c": 25.0,
        "humidity_percent": 50.0,
        "soil_ao_raw": 2000,
        "uptime_ms": 50000,
    }

    # First update at t0
    norm1, _ = svc.validate_and_normalize(reading, recorded_at=t0)
    assert norm1["device_health"]["is_stale"] is False

    # Second update at t1 with same uptime_ms (frozen device)
    norm2, _ = svc.validate_and_normalize(reading, recorded_at=t1)
    assert norm2["device_health"]["is_stale"] is True
    assert norm2["device_health"]["is_online"] is False
