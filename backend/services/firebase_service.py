import os
import logging
from typing import Dict, Any, Optional, List
import firebase_admin
from firebase_admin import credentials, db

logger = logging.getLogger("agrisense.firebase")

class FirebaseService:
    """Manages Firebase Realtime Database connection and operations."""

    def __init__(self, database_url: str, credential_path: str):
        self.database_url = database_url
        self.credential_path = credential_path
        self.app = None
        self.is_initialized = False
        self._init_error = None
        self._initialize()

    def _initialize(self):
        """Initializes the Firebase Admin SDK singleton."""
        if not self.credential_path or not os.path.exists(self.credential_path):
            self._init_error = f"Service account file does not exist at: {self.credential_path}"
            logger.error(self._init_error)
            self.is_initialized = False
            return

        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(self.credential_path)
                self.app = firebase_admin.initialize_app(
                    cred,
                    {"databaseURL": self.database_url},
                )
            else:
                self.app = firebase_admin.get_app()

            self.is_initialized = True
            logger.info("Firebase Admin successfully initialized with RTDB URL: %s", self.database_url)
        except Exception as e:
            self.is_initialized = False
            self._init_error = str(e)
            logger.error("Failed to initialize Firebase Admin: %s", e)

    def get_status(self) -> Dict[str, Any]:
        """Returns the health status of Firebase connection."""
        return {
            "initialized": self.is_initialized,
            "database_url": self.database_url,
            "error": self._init_error,
        }

    def get_live_reading(self) -> Optional[Dict[str, Any]]:
        """
        Fetches the latest reading from /AgriSense/live.
        Returns None if not initialized or on failure.
        """
        if not self.is_initialized:
            logger.warning("Attempted to fetch live reading but Firebase is not initialized.")
            return None

        try:
            ref = db.reference("/AgriSense/live")
            data = ref.get()
            if isinstance(data, dict):
                return data
            return None
        except Exception as e:
            logger.error("Error reading /AgriSense/live: %s", e)
            return None

    def save_history_point(self, point_key: str, reading_data: Dict[str, Any]) -> bool:
        """
        Stores a timestamped reading under /AgriSense/history/<point_key>.
        """
        if not self.is_initialized:
            return False

        try:
            ref = db.reference(f"/AgriSense/history/{point_key}")
            ref.set(reading_data)
            return True
        except Exception as e:
            logger.error("Error writing to /AgriSense/history/%s: %s", point_key, e)
            return False

    def get_history(self, start_key: Optional[str] = None, end_key: Optional[str] = None, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Fetches historical records from /AgriSense/history with bounded queries.
        """
        if not self.is_initialized:
            return []

        try:
            ref = db.reference("/AgriSense/history")
            query = ref.order_by_key()

            if start_key and end_key:
                query = query.start_at(start_key).end_at(end_key)
            elif start_key:
                query = query.start_at(start_key)

            if limit and limit > 0:
                query = query.limit_to_last(limit)

            data = query.get()
            if not data or not isinstance(data, dict):
                return []

            results = []
            for k in sorted(data.keys()):
                entry = data[k]
                if isinstance(entry, dict):
                    if "id" not in entry:
                        entry["id"] = k
                    results.append(entry)
            return results
        except Exception as e:
            logger.error("Error fetching history: %s", e)
            return []

    def save_prediction(self, prediction_data: Dict[str, Any]) -> bool:
        """Saves latest prediction to /AgriSense/predictions/latest."""
        if not self.is_initialized:
            return False

        try:
            ref = db.reference("/AgriSense/predictions/latest")
            ref.set(prediction_data)
            return True
        except Exception as e:
            logger.error("Error saving prediction to Firebase: %s", e)
            return False

    def get_latest_prediction(self) -> Optional[Dict[str, Any]]:
        """Fetches latest prediction from /AgriSense/predictions/latest."""
        if not self.is_initialized:
            return None

        try:
            ref = db.reference("/AgriSense/predictions/latest")
            data = ref.get()
            if isinstance(data, dict):
                return data
            return None
        except Exception as e:
            logger.error("Error reading /AgriSense/predictions/latest: %s", e)
            return None
