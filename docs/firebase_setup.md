# AgriSense Firebase Setup & Schema Guide

## 1. Firebase Realtime Database Target
- **Database URL:** `https://agrisense-ed6c9-default-rtdb.firebaseio.com/`
- **Location:** us-central1 default RTDB instance
- **Project ID:** `agrisense-ed6c9`

---

## 2. Authentication & Admin SDK
The backend connects using the Firebase Admin Python SDK via a Google Service Account credential.
- Environment Variable: `FIREBASE_SERVICE_ACCOUNT=backend/agrisense-ed6c9-firebase-adminsdk-fbsvc-8111f401b3.json`
- **Security Rule:** Never commit the service account JSON key to Git or distribute it inside the Flutter mobile application package.

---

## 3. Database Schema

### 3.1 Live Telemetry Node (`/AgriSense/live`)
The ESP32 firmware writes its latest readings to this single node:
```json
{
  "dht_valid": true,
  "temperature_c": 28.7,
  "humidity_percent": 62.1,
  "soil_ao_raw": 4095,
  "soil_do": 1,
  "soil_status": "DRY",
  "soil_adc_range_percent": 100,
  "soil_moisture_estimate_percent": 0.0,
  "wifi_rssi_dbm": -72,
  "uptime_ms": 661134
}
```

### 3.2 Historical Telemetry Node (`/AgriSense/history/<timestamp_ms>`)
Created and maintained by the backend `HistoryService`:
```json
{
  "1792706747190": {
    "id": "1792706747190",
    "timestamp": "2026-10-23T03:30:00Z",
    "timestamp_ms": 1792706747190,
    "uptime_ms": 661134,
    "temperature_c": 28.7,
    "humidity_percent": 62.1,
    "soil_moisture_estimate_percent": 35.4,
    "soil_ao_raw": 3150,
    "soil_do": 1,
    "soil_status": "DRY",
    "wifi_rssi_dbm": -72,
    "valid": true
  }
}
```

### 3.3 Predictions Node (`/AgriSense/predictions/latest`)
Stores the latest ML inference results:
```json
{
  "available": true,
  "prediction_type": "irrigation_need",
  "irrigation_needed": true,
  "confidence": 0.985,
  "model_version": "v1.0.0-rf-agronomic",
  "prediction_timestamp": "2026-10-23T03:30:01Z",
  "explanation": [
    "Soil moisture is at 35.4%, indicating moisture deficit for loam soil under wheat cultivation."
  ]
}
```

---

## 4. Recommended Realtime Database Security Rules
In Firebase Console, configure security rules to protect the database while allowing authenticated ESP32 updates and backend Admin SDK access:
```json
{
  "rules": {
    "AgriSense": {
      "live": {
        ".read": "auth != null",
        ".write": "auth != null"
      },
      "history": {
        ".read": "auth != null",
        ".write": false,
        ".indexOn": [".key"]
      },
      "predictions": {
        ".read": "auth != null",
        ".write": false
      }
    }
  }
}
```
*Note: Firebase Admin SDK initialized with a service account certificate bypasses client security rules on the backend while keeping the database locked against public anonymous tampering.*
