import os
import sys
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

# Ensure project root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

import firebase_admin
from firebase_admin import credentials, db
from backend.config import Config

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("agrisense.migrate")

def inspect_and_report_history():
    """Reads current history statistics from Firebase Realtime Database."""
    if not os.path.exists(Config.FIREBASE_SERVICE_ACCOUNT):
        logger.error("Firebase credentials not found at %s", Config.FIREBASE_SERVICE_ACCOUNT)
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(Config.FIREBASE_SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {"databaseURL": Config.FIREBASE_DATABASE_URL})

    ref = db.reference("/AgriSense/history")
    data = ref.get()

    if not data or not isinstance(data, dict):
        logger.info("No historical records currently found under /AgriSense/history.")
        return

    keys = list(data.keys())
    logger.info("Total historical points recorded: %d", len(keys))
    logger.info("Earliest record: %s", keys[0])
    logger.info("Latest record:   %s", keys[-1])

    # Sample latest entry
    sample = data[keys[-1]]
    logger.info("Sample record: %s", json.dumps(sample, indent=2))

if __name__ == "__main__":
    inspect_and_report_history()
