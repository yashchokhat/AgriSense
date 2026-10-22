import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Optional
from backend.services.firebase_service import FirebaseService

logger = logging.getLogger("agrisense.history")

class HistoryService:
    """Manages historical sensor data deduplication, ingestion, and time-bounded querying."""

    def __init__(self, firebase_service: FirebaseService, max_memory_records: int = 500):
        self.firebase = firebase_service
        self.max_memory_records = max_memory_records
        self.last_ingested_uptime_ms: Optional[int] = None
        self.last_ingested_at: Optional[datetime] = None
        # Local buffer for fast access and fallback
        self._local_history: List[Dict[str, Any]] = []

    def ingest_reading(self, normalized_data: Dict[str, Any]) -> bool:
        """
        Deduplicates and stores a new historical point if it represents a new reading.
        Returns True if saved, False if skipped as duplicate or invalid.
        """
        if not normalized_data:
            return False

        uptime_ms = normalized_data.get("uptime_ms")
        now = datetime.now(timezone.utc)

        # Deduplication check: ESP32 uptime_ms must have progressed
        if self.last_ingested_uptime_ms is not None and uptime_ms == self.last_ingested_uptime_ms:
            # Same reading; do not save duplicate
            return False

        # Throttle safeguard: minimum 2 seconds between history points
        if self.last_ingested_at is not None:
            elapsed = (now - self.last_ingested_at).total_seconds()
            if elapsed < 2.0:
                return False

        timestamp_ms = int(now.timestamp() * 1000)
        point_key = str(timestamp_ms)

        history_point = {
            "id": point_key,
            "timestamp": now.isoformat(),
            "timestamp_ms": timestamp_ms,
            "uptime_ms": uptime_ms,
            "temperature_c": normalized_data["calibrated"]["temperature_c"],
            "humidity_percent": normalized_data["calibrated"]["humidity_percent"],
            "soil_moisture_estimate_percent": normalized_data["calibrated"]["soil_moisture_estimate_percent"],
            "soil_ao_raw": normalized_data["raw"]["soil_ao_raw"],
            "soil_do": normalized_data["raw"]["soil_do"],
            "soil_status": normalized_data["threshold_status"]["soil_status"],
            "wifi_rssi_dbm": normalized_data["raw"]["wifi_rssi_dbm"],
            "valid": normalized_data["quality"]["all_valid"],
        }

        # Update tracking
        self.last_ingested_uptime_ms = uptime_ms
        self.last_ingested_at = now

        # Add to local cache
        self._local_history.append(history_point)
        if len(self._local_history) > self.max_memory_records:
            self._local_history.pop(0)

        # Persist to Firebase RTDB
        if self.firebase and self.firebase.is_initialized:
            try:
                self.firebase.save_history_point(point_key, history_point)
                logger.info("Persisted historical point %s (uptime=%s)", point_key, uptime_ms)
                return True
            except Exception as e:
                logger.error("Failed to persist history point %s: %s", point_key, e)
                return False

        return True

    def get_history(self, hours: float = 24.0, limit: int = 150) -> Dict[str, Any]:
        """
        Retrieves historical records within the given time window.
        Returns a dictionary with summary statistics and sorted points.
        """
        limit = max(1, min(limit, 1000))
        now = datetime.now(timezone.utc)
        cutoff_dt = now - timedelta(hours=hours)
        cutoff_ms = int(cutoff_dt.timestamp() * 1000)
        start_key = str(cutoff_ms)

        records: List[Dict[str, Any]] = []

        # Try Firebase first if connected
        if self.firebase and self.firebase.is_initialized:
            remote_records = self.firebase.get_history(start_key=start_key, limit=limit)
            if remote_records:
                records = remote_records

        # If remote is empty or offline, use local buffer
        if not records and self._local_history:
            records = [
                pt for pt in self._local_history
                if pt.get("timestamp_ms", 0) >= cutoff_ms
            ][-limit:]

        # Calculate statistics over the returned series
        temps = [r["temperature_c"] for r in records if r.get("temperature_c") is not None]
        humids = [r["humidity_percent"] for r in records if r.get("humidity_percent") is not None]
        soils = [r["soil_moisture_estimate_percent"] for r in records if r.get("soil_moisture_estimate_percent") is not None]

        stats = {
            "count": len(records),
            "window_hours": hours,
            "temperature": {
                "min": round(min(temps), 1) if temps else None,
                "max": round(max(temps), 1) if temps else None,
                "avg": round(sum(temps) / len(temps), 1) if temps else None,
            },
            "humidity": {
                "min": round(min(humids), 1) if humids else None,
                "max": round(max(humids), 1) if humids else None,
                "avg": round(sum(humids) / len(humids), 1) if humids else None,
            },
            "soil_moisture": {
                "min": round(min(soils), 1) if soils else None,
                "max": round(max(soils), 1) if soils else None,
                "avg": round(sum(soils) / len(soils), 1) if soils else None,
            }
        }

        return {
            "summary": stats,
            "records": records,
        }
