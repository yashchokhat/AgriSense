import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional

logger = logging.getLogger("agrisense.alerts")

class AlertService:
    """Evaluates sensor readings and device state to generate genuine operational alerts."""

    def __init__(
        self,
        temp_min: float = 10.0,
        temp_max: float = 38.0,
        humidity_min: float = 25.0,
        humidity_max: float = 85.0,
        soil_critical_low: float = 25.0,
        soil_critical_high: float = 85.0,
    ):
        self.temp_min = temp_min
        self.temp_max = temp_max
        self.humidity_min = humidity_min
        self.humidity_max = humidity_max
        self.soil_critical_low = soil_critical_low
        self.soil_critical_high = soil_critical_high

    def evaluate_alerts(self, normalized_reading: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Evaluates normalized reading and device health to return a list of active alerts.
        """
        alerts: List[Dict[str, Any]] = []
        now = datetime.now(timezone.utc)

        if not normalized_reading:
            alerts.append({
                "id": f"alert_node_missing_{int(now.timestamp())}",
                "severity": "CRITICAL",
                "title": "ESP32 Disconnected",
                "message": "No live sensor telemetry received from ESP32.",
                "category": "DEVICE",
                "timestamp": now.isoformat(),
                "sensor_value": None,
                "unit": None,
                "acknowledged": False,
            })
            return alerts

        health = normalized_reading.get("device_health", {})
        quality = normalized_reading.get("quality", {})
        calibrated = normalized_reading.get("calibrated", {})
        raw = normalized_reading.get("raw", {})
        threshold = normalized_reading.get("threshold_status", {})

        # 1. Device staleness alert
        if health.get("is_stale", False):
            secs = health.get("seconds_since_last_seen", 0)
            alerts.append({
                "id": "alert_device_stale",
                "severity": "WARNING",
                "title": "Device Signal Stale",
                "message": f"ESP32 has not broadcast updated telemetry for {int(secs)} seconds.",
                "category": "CONNECTIVITY",
                "timestamp": health.get("last_seen_timestamp", now.isoformat()),
                "sensor_value": secs,
                "unit": "seconds",
                "acknowledged": False,
            })

        # 2. Hardware Sensor Read Failures
        if not quality.get("dht_valid", True):
            alerts.append({
                "id": "alert_dht_fault",
                "severity": "ERROR",
                "title": "DHT11 Sensor Read Fault",
                "message": "DHT11 temperature/humidity sensor reported a hardware read error.",
                "category": "HARDWARE",
                "timestamp": now.isoformat(),
                "sensor_value": None,
                "unit": None,
                "acknowledged": False,
            })

        if not quality.get("soil_valid", True):
            alerts.append({
                "id": "alert_soil_sensor_fault",
                "severity": "ERROR",
                "title": "Soil Moisture Sensor Fault",
                "message": "Soil moisture sensor raw ADC out of bounds.",
                "category": "HARDWARE",
                "timestamp": now.isoformat(),
                "sensor_value": raw.get("soil_ao_raw"),
                "unit": "ADC",
                "acknowledged": False,
            })

        # 3. Critical Soil Moisture Depletion
        moisture = calibrated.get("soil_moisture_estimate_percent")
        soil_status = threshold.get("soil_status")
        if moisture is not None:
            if moisture < self.soil_critical_low or soil_status == "DRY":
                alerts.append({
                    "id": "alert_soil_dry",
                    "severity": "CRITICAL",
                    "title": "Critical Soil Moisture Deficit",
                    "message": f"Soil moisture has dropped to {moisture}%. Crops at risk of water stress.",
                    "category": "IRRIGATION",
                    "timestamp": now.isoformat(),
                    "sensor_value": moisture,
                    "unit": "%",
                    "acknowledged": False,
                })
            elif moisture > self.soil_critical_high:
                alerts.append({
                    "id": "alert_soil_waterlogged",
                    "severity": "WARNING",
                    "title": "Soil Saturated",
                    "message": f"Soil moisture is {moisture}%. Risk of root anoxia or fungal development.",
                    "category": "IRRIGATION",
                    "timestamp": now.isoformat(),
                    "sensor_value": moisture,
                    "unit": "%",
                    "acknowledged": False,
                })

        # 4. Temperature Extremes
        temp = calibrated.get("temperature_c")
        if temp is not None:
            if temp > self.temp_max:
                alerts.append({
                    "id": "alert_high_temp",
                    "severity": "WARNING",
                    "title": "High Ambient Heat Warning",
                    "message": f"Ambient temperature is {temp}°C, exceeding safe upper limit ({self.temp_max}°C).",
                    "category": "ENVIRONMENT",
                    "timestamp": now.isoformat(),
                    "sensor_value": temp,
                    "unit": "°C",
                    "acknowledged": False,
                })
            elif temp < self.temp_min:
                alerts.append({
                    "id": "alert_low_temp",
                    "severity": "WARNING",
                    "title": "Low Temperature Chill Alert",
                    "message": f"Temperature is {temp}°C, approaching cold stress thresholds.",
                    "category": "ENVIRONMENT",
                    "timestamp": now.isoformat(),
                    "sensor_value": temp,
                    "unit": "°C",
                    "acknowledged": False,
                })

        # 5. Humidity extremes
        humidity = calibrated.get("humidity_percent")
        if humidity is not None:
            if humidity < self.humidity_min:
                alerts.append({
                    "id": "alert_low_humidity",
                    "severity": "INFO",
                    "title": "Dry Atmospheric Air",
                    "message": f"Relative humidity is {humidity}%, causing higher plant transpiration.",
                    "category": "ENVIRONMENT",
                    "timestamp": now.isoformat(),
                    "sensor_value": humidity,
                    "unit": "%",
                    "acknowledged": False,
                })
            elif humidity > self.humidity_max:
                alerts.append({
                    "id": "alert_high_humidity",
                    "severity": "INFO",
                    "title": "High Humidity Condition",
                    "message": f"Relative humidity is {humidity}%. Monitor for fungal foliar diseases.",
                    "category": "ENVIRONMENT",
                    "timestamp": now.isoformat(),
                    "sensor_value": humidity,
                    "unit": "%",
                    "acknowledged": False,
                })

        return alerts
