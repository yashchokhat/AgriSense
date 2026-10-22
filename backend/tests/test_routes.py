import json
import pytest

def test_health_route(client):
    res = client.get("/api/v1/health")
    assert res.status_code in (200, 207)
    data = res.get_json()
    assert data["success"] is True
    assert "services" in data["data"]
    assert "firebase" in data["data"]["services"]
    assert "ml_engine" in data["data"]["services"]

def test_dashboard_route(client):
    res = client.get("/api/v1/dashboard")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    body = data["data"]
    assert "device" in body
    assert "telemetry" in body
    assert "recommendation" in body
    assert "alerts_summary" in body
    assert body["telemetry"]["calibrated"]["temperature_c"] == 28.5

def test_sensors_latest_route(client):
    res = client.get("/api/v1/sensors/latest")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["data"]["raw"]["soil_ao_raw"] == 3200

def test_sensors_history_route(client):
    res = client.get("/api/v1/sensors/history?hours=24&limit=50")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert "summary" in data["data"]
    assert "records" in data["data"]

def test_sensors_history_invalid_params(client):
    # Negative hours
    res = client.get("/api/v1/sensors/history?hours=-5")
    assert res.status_code == 400
    data = res.get_json()
    assert data["success"] is False
    assert data["error"]["code"] == "INVALID_PARAMETER"

    # Non-numeric limit
    res2 = client.get("/api/v1/sensors/history?limit=abc")
    assert res2.status_code == 400

def test_predictions_latest_route(client):
    res = client.get("/api/v1/predictions/latest")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["data"]["available"] is True

def test_predictions_run_route(client):
    payload = {
        "crop_type": "tomato",
        "soil_type": "clay",
    }
    res = client.post("/api/v1/predictions/run", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["data"]["available"] is True

def test_alerts_route(client):
    res = client.get("/api/v1/alerts")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert "summary" in data["data"]
    assert "alerts" in data["data"]

def test_config_route(client):
    res = client.get("/api/v1/config")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert "thresholds" in data["data"]
    assert "options" in data["data"]

def test_update_config_route(client):
    payload = {
        "thresholds": {
            "soil_moisture_critical_low": 28.0,
        }
    }
    res = client.post("/api/v1/config", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["data"]["updated"]["soil_moisture_critical_low"] == 28.0

def test_404_error_handler(client):
    res = client.get("/api/v1/non_existent_route")
    assert res.status_code == 404
    data = res.get_json()
    assert data["success"] is False
    assert data["error"]["code"] == "NOT_FOUND"
