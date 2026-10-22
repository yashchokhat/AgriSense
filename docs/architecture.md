# AgriSense Architecture Documentation

## 1. System Overview
AgriSense is a production-grade IoT smart agriculture platform designed to provide precision soil monitoring, microclimate tracking, and machine-learning-driven irrigation intelligence.

```mermaid
flowchart TD
    subgraph EdgeHardware["1. Hardware Edge Node (ESP32)"]
        DHT11["DHT11 Sensor\n(GPIO 27)"] --> ESP["ESP32 Microcontroller"]
        SoilAO["Soil Sensor AO (ADC)\n(GPIO 35)"] --> ESP
        SoilDO["Soil Sensor DO (Threshold)\n(GPIO 34)"] --> ESP
        ESP -->|HTTPS REST / JSON\n1s stream| FirebaseRTDB[("/AgriSense/live")]
    end

    subgraph CloudData["2. Firebase Cloud Infrastructure"]
        FirebaseRTDB -->|Admin SDK| Backend["Flask REST API Engine\n(Python 3)"]
        Backend -->|Deduplicated Batch Ingestion| FirebaseHistory[("/AgriSense/history")]
        Backend -->|Prediction Cache| FirebasePred[("/AgriSense/predictions")]
    end

    subgraph BackendCore["3. Backend Microservices"]
        Backend --> SensorSvc["Sensor Quality & Validation Layer"]
        Backend --> HistorySvc["Historical Time-Window Query Engine"]
        Backend --> AlertSvc["Operational Alert Engine"]
        Backend --> RecSvc["Recommendation & ML Service"]
        RecSvc --> ML["Random Forest Irrigation Model\n(scikit-learn)"]
        RecSvc --> RuleFallback["Agronomic FAO-56 Rule Fallback"]
    end

    subgraph ClientApp["4. Cross-Platform Mobile Client (Flutter)"]
        Backend -->|REST API v1\nBounded JSON| MobileApp["AgriSense Flutter App"]
        MobileApp --> DashScreen["1. Home Dashboard"]
        MobileApp --> AnalyticsScreen["2. Sensor Analytics (fl_chart)"]
        MobileApp --> AiScreen["3. AI Insights & Factors"]
        MobileApp --> AlertScreen["4. Active Alerts & Notifications"]
        MobileApp --> SettingsScreen["5. Farm Profile & Host Config"]
    end
```

---

## 2. Component Design

### 2.1 Edge IoT Layer
- **Microcontroller:** ESP32 Dev Module.
- **Microclimate:** DHT11 sensor measuring Temperature (0–50°C, ±2°C) and Relative Humidity (20–90% RH, ±5%). Connected to GPIO 27.
- **Soil Moisture:** Capacitive/resistive soil sensor with:
  - Analog output (AO) connected to GPIO 35 (12-bit ADC: 0 to 4095).
  - Digital output (DO) connected to GPIO 34 (threshold comparator).
- **Network Protocol:** WiFi 802.11 b/g/n broadcasting JSON telemetry to Firebase Realtime Database.

### 2.2 Data Quality & Health Layer (`SensorService`)
To protect against sensor failure, loose wiring, or stale telemetry:
1. **Physical Plausibility Bounds:** Implausible readings (e.g. DHT11 > 60°C or negative humidity) are detected and flagged.
2. **ADC Normalization:** The 12-bit ADC value (0–4095) is preserved as raw data and separately calibrated into a percentage estimate ($0\%$ at air $4095$, $100\%$ at saturation $\le 1400$).
3. **Staleness Tracking:** Tracks device `uptime_ms` progression and observation intervals against a configurable timeout (default 60s).

### 2.3 History Deduplication & Ingestion (`HistoryService`)
- Overcomes the firmware limitation of overwriting only `/AgriSense/live`.
- Ingestion checks for genuine device progression (`uptime_ms` delta) and enforces a 2-second rate limit.
- Timestamped records are written to `/AgriSense/history/<timestamp_ms>`.
- Provides time-bounded range querying with minimum, maximum, and average statistics.

### 2.4 ML & Agronomic Recommendation Layer (`RecommendationService`)
- Integrates a trained `RandomForestClassifier` scoring soil moisture deficit, atmospheric drying power (Vapor Pressure Deficit, VPD), ambient temperature, crop sensitivity, and soil retention characteristics.
- If the model is not trained or telemetry fails validation, it falls back transparently to configurable agronomic rules (FAO-56 guidelines), clearly distinguished in the UI.

### 2.5 Mobile Presentation Layer (`Flutter`)
- Built with Dart 3 & Flutter Material 3.
- State management with `Provider` and dynamic host resolution.
- Responsive, accessible layouts with customized chart rendering (`fl_chart`).
