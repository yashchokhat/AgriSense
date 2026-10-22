import math
import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, Tuple, List, Optional

logger = logging.getLogger("agrisense.sensor")

class SensorService:
    """Validates, categorizes, and normalizes sensor readings and device health."""

    def __init__(self, stale_timeout_seconds: int = 60):
        self.stale_timeout_seconds = stale_timeout_seconds
        # In-memory tracking for staleness and deduplication
        self.last_seen_timestamp: Optional[datetime] = None
        self.last_uptime_ms: Optional[int] = None
        self.last_valid_reading: Optional[Dict[str, Any]] = None

    def validate_and_normalize(
        self,
        raw_data: Optional[Dict[str, Any]],
        recorded_at: Optional[datetime] = None
    ) -> Tuple[Optional[Dict[str, Any]], List[str]]:
        """
        Validates raw payload from Firebase /AgriSense/live.
        Returns a tuple of (normalized_dict, warnings_list).
        If data is invalid or empty, returns (None, errors).
        """
        warnings: List[str] = []
        if not raw_data or not isinstance(raw_data, dict):
            return None, ["No sensor data provided or invalid format."]

        now = recorded_at or datetime.now(timezone.utc)

        # 1. Parse uptime & check device progression
        uptime_ms = self._safe_int(raw_data.get("uptime_ms"))
        if uptime_ms is None or uptime_ms < 0:
            warnings.append("Missing or invalid uptime_ms.")
            uptime_ms = 0

        # Update last seen tracking
        if self.last_uptime_ms is None or uptime_ms != self.last_uptime_ms:
            # Device has updated or initialized
            self.last_seen_timestamp = now
            self.last_uptime_ms = uptime_ms
        elif self.last_seen_timestamp is None:
            self.last_seen_timestamp = now

        # Staleness check
        seconds_since_last_seen = (now - self.last_seen_timestamp).total_seconds()
        is_stale = seconds_since_last_seen > self.stale_timeout_seconds
        is_online = not is_stale

        if is_stale:
            warnings.append(
                f"Sensor reading is stale (last observed {int(seconds_since_last_seen)}s ago)."
            )

        # 2. Temperature validation (DHT11 rated: 0 to 50 °C)
        temp_c = self._safe_float(raw_data.get("temperature_c"))
        dht_valid_flag = bool(raw_data.get("dht_valid", True))
        temp_valid = True

        if temp_c is None:
            temp_valid = False
            warnings.append("Missing or non-numeric temperature.")
        elif temp_c < -10.0 or temp_c > 60.0:
            temp_valid = False
            warnings.append(f"Temperature {temp_c}°C is outside plausible physical range (-10°C to 60°C).")
        elif not dht_valid_flag:
            temp_valid = False
            warnings.append("DHT sensor reported internal read error (dht_valid=false).")

        # 3. Humidity validation (DHT11 rated: 20 to 90 % RH)
        humidity_pct = self._safe_float(raw_data.get("humidity_percent"))
        humidity_valid = True

        if humidity_pct is None:
            humidity_valid = False
            warnings.append("Missing or non-numeric humidity.")
        elif humidity_pct < 0.0 or humidity_pct > 100.0:
            humidity_valid = False
            warnings.append(f"Humidity {humidity_pct}% is outside physical boundary (0-100%).")

        # 4. Soil moisture sensor validation
        # soil_ao_raw: ESP32 ADC (0 to 4095)
        soil_ao_raw = self._safe_int(raw_data.get("soil_ao_raw"))
        soil_valid = True

        if soil_ao_raw is None:
            soil_valid = False
            warnings.append("Missing or non-numeric soil_ao_raw.")
        elif soil_ao_raw < 0 or soil_ao_raw > 4095:
            soil_valid = False
            warnings.append(f"Soil raw ADC {soil_ao_raw} is outside valid 12-bit range (0-4095).")

        # soil_do: Digital threshold (0 or 1)
        soil_do = self._safe_int(raw_data.get("soil_do"))
        if soil_do not in (0, 1):
            soil_do = 1 if (soil_ao_raw and soil_ao_raw > 2500) else 0

        # Calibrated moisture estimate (%)
        soil_moisture_estimate = self._safe_float(raw_data.get("soil_moisture_estimate_percent"))
        if soil_moisture_estimate is None:
            # Calibrate from soil_ao_raw: In typical ESP32 analog soil sensors,
            # 4095 = completely dry air, ~1500 = water saturated
            if soil_ao_raw is not None:
                # Clamp raw ADC
                clamped_adc = max(1400, min(4095, soil_ao_raw))
                # Inverse relationship: higher ADC = drier soil
                soil_moisture_estimate = round(((4095 - clamped_adc) / (4095 - 1400)) * 100.0, 1)
            else:
                soil_moisture_estimate = 0.0
        else:
            soil_moisture_estimate = max(0.0, min(100.0, round(soil_moisture_estimate, 1)))

        # Status categorization
        soil_status = raw_data.get("soil_status")
        if not soil_status or not isinstance(soil_status, str):
            if soil_moisture_estimate < 30.0:
                soil_status = "DRY"
            elif soil_moisture_estimate <= 75.0:
                soil_status = "OPTIMAL"
            else:
                soil_status = "WET"
        else:
            soil_status = soil_status.upper().strip()

        # 5. WiFi RSSI & connectivity
        wifi_rssi = self._safe_int(raw_data.get("wifi_rssi_dbm"))
        wifi_signal_quality = self._classify_rssi(wifi_rssi)

        # 6. Overall validity
        dht_overall_valid = temp_valid and humidity_valid and dht_valid_flag
        all_valid = dht_overall_valid and soil_valid

        normalized: Dict[str, Any] = {
            "timestamp": now.isoformat(),
            "uptime_ms": uptime_ms,
            "raw": {
                "soil_ao_raw": soil_ao_raw,
                "soil_do": soil_do,
                "soil_adc_range_percent": self._safe_float(raw_data.get("soil_adc_range_percent")),
                "wifi_rssi_dbm": wifi_rssi,
            },
            "calibrated": {
                "temperature_c": round(temp_c, 1) if temp_c is not None else None,
                "humidity_percent": round(humidity_pct, 1) if humidity_pct is not None else None,
                "soil_moisture_estimate_percent": soil_moisture_estimate,
            },
            "units": {
                "temperature": "°C",
                "humidity": "%",
                "soil_moisture_estimate": "%",
                "soil_ao_raw": "ADC (12-bit, 0-4095)",
                "wifi_rssi": "dBm",
                "uptime": "ms",
            },
            "threshold_status": {
                "soil_status": soil_status,
                "soil_do_threshold_active": soil_do == 0,
            },
            "quality": {
                "dht_valid": dht_overall_valid,
                "soil_valid": soil_valid,
                "all_valid": all_valid,
                "warnings": warnings,
            },
            "device_health": {
                "is_online": is_online,
                "is_stale": is_stale,
                "last_seen_timestamp": self.last_seen_timestamp.isoformat() if self.last_seen_timestamp else now.isoformat(),
                "seconds_since_last_seen": round(seconds_since_last_seen, 1),
                "wifi_quality": wifi_signal_quality,
            }
        }

        if all_valid:
            self.last_valid_reading = normalized

        return normalized, warnings

    def _classify_rssi(self, rssi: Optional[int]) -> str:
        if rssi is None:
            return "UNKNOWN"
        if rssi >= -55:
            return "EXCELLENT"
        if rssi >= -70:
            return "GOOD"
        if rssi >= -85:
            return "FAIR"
        return "WEAK"

    def _safe_float(self, val: Any) -> Optional[float]:
        if val is None:
            return None
        try:
            num = float(val)
            if math.isnan(num) or math.isinf(num):
                return None
            return num
        except (ValueError, TypeError):
            return None

    def _safe_int(self, val: Any) -> Optional[int]:
        if val is None:
            return None
        try:
            num = float(val)
            if math.isnan(num) or math.isinf(num):
                return None
            return int(num)
        except (ValueError, TypeError):
            return None
