# AgriSense REST API Documentation

Base URL: `http://<HOST>:<PORT>/api/v1`

All responses follow a consistent envelope structure:
```json
{
  "success": true,
  "data": {},
  "meta": {
    "timestamp": "2026-10-23T03:30:00Z",
    "version": "1.0.0"
  },
  "error": null
}
```

---

## 1. Health & Status

### `GET /health`
Returns system status, Firebase connection state, and ML model availability.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "api_version": "1.0.0",
    "services": {
      "firebase": {
        "connected": true,
        "rtdb_target": "configured"
      },
      "ml_engine": {
        "available": true,
        "model_version": "v1.0.0-rf-agronomic"
      }
    }
  }
}
```

---

## 2. Dashboard

### `GET /dashboard`
Provides a consolidated payload containing live telemetry, device connectivity, active alerts, current recommendation, and 24-hour summary trends.

**Query Parameters:**
- `crop_type` (optional, string): Crop context (default: `general`). Options: `general`, `wheat`, `tomato`, `maize`, `cotton`, `rice`.
- `soil_type` (optional, string): Soil context (default: `loam`). Options: `sand`, `loam`, `clay`.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "device": {
      "device_id": "ESP32_AGRISENSE_01",
      "is_online": true,
      "is_stale": false,
      "last_seen_timestamp": "2026-10-23T03:30:00Z",
      "seconds_since_last_seen": 1.2,
      "wifi_quality": "GOOD",
      "wifi_rssi_dbm": -72,
      "uptime_ms": 661134
    },
    "telemetry": {
      "has_data": true,
      "timestamp": "2026-10-23T03:30:00Z",
      "calibrated": {
        "temperature_c": 28.7,
        "humidity_percent": 62.1,
        "soil_moisture_estimate_percent": 35.4
      },
      "raw": {
        "soil_ao_raw": 3150,
        "soil_do": 1,
        "wifi_rssi_dbm": -72
      },
      "units": {
        "temperature": "°C",
        "humidity": "%",
        "soil_moisture_estimate": "%",
        "soil_ao_raw": "ADC (12-bit, 0-4095)"
      },
      "threshold_status": {
        "soil_status": "DRY",
        "soil_do_threshold_active": false
      },
      "quality": {
        "all_valid": true,
        "dht_valid": true,
        "soil_valid": true,
        "warnings": []
      }
    },
    "recommendation": {
      "available": true,
      "recommendation_type": "ml_prediction",
      "irrigation_needed": true,
      "urgency": "HIGH",
      "confidence": 0.985,
      "is_ml_based": true,
      "model_version": "v1.0.0-rf-agronomic",
      "title": "Irrigation Recommended (ML)",
      "message": "Machine learning model predicts active moisture deficit for wheat in loam soil.",
      "explanation": [
        "Soil moisture is at 35.4%, indicating moisture deficit for loam soil under wheat cultivation.",
        "Atmospheric vapor pressure deficit (VPD) is elevated at 1.49 kPa."
      ]
    },
    "alerts_summary": {
      "count": 1,
      "critical_count": 0,
      "items": [...]
    },
    "trends_24h": {
      "count": 48,
      "temperature": {"min": 22.1, "max": 31.4, "avg": 26.8},
      "soil_moisture": {"min": 32.0, "max": 75.0, "avg": 48.2}
    }
  }
}
```

---

## 3. Sensors

### `GET /sensors/latest`
Returns only the validated latest sensor payload.

### `GET /sensors/history`
Returns chronological records and computed statistics.

**Query Parameters:**
- `hours` (float, default `24.0`, min `0.1`, max `720.0`): Time window to query.
- `limit` (int, default `100`, min `1`, max `500`): Maximum data points returned.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "count": 2,
      "window_hours": 24.0,
      "temperature": {"min": 24.5, "max": 28.7, "avg": 26.6},
      "humidity": {"min": 58.0, "max": 65.2, "avg": 61.6},
      "soil_moisture": {"min": 35.4, "max": 42.0, "avg": 38.7}
    },
    "records": [
      {
        "id": "1792706747190",
        "timestamp": "2026-10-23T03:00:00Z",
        "temperature_c": 28.7,
        "humidity_percent": 62.1,
        "soil_moisture_estimate_percent": 35.4,
        "soil_ao_raw": 3150,
        "soil_status": "DRY",
        "valid": true
      }
    ]
  }
}
```

---

## 4. Predictions

### `GET /predictions/latest`
Fetches the current recommendation evaluation.

### `POST /predictions/run`
Forces an immediate inference run with given agricultural context.

**Request Body:**
```json
{
  "crop_type": "tomato",
  "soil_type": "clay",
  "force_rule_based": false
}
```

---

## 5. Alerts

### `GET /alerts`
Returns active alerts with severity levels (`CRITICAL`, `WARNING`, `INFO`, `ERROR`).

---

## 6. Configuration

### `GET /config`
Returns current operational thresholds and supported crop/soil choices.

### `POST /config`
Updates runtime thresholds safely.
