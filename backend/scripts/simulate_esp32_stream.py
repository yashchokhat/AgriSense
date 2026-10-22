import os
import sys
import time
import random
import logging
from pathlib import Path

# Ensure project root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

import firebase_admin
from firebase_admin import credentials, db
from backend.config import Config

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("agrisense.simulator")

def run_simulator(interval_seconds: float = 3.0, iterations: int = 100):
    """
    Simulates real ESP32 telemetry updates to /AgriSense/live on Firebase RTDB.
    Useful for live integration testing, demonstrating dynamic chart updates, and alerts.
    """
    if not os.path.exists(Config.FIREBASE_SERVICE_ACCOUNT):
        logger.error("Firebase credentials not found at %s", Config.FIREBASE_SERVICE_ACCOUNT)
        return

    if not firebase_admin._apps:
        cred = credentials.Certificate(Config.FIREBASE_SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {"databaseURL": Config.FIREBASE_DATABASE_URL})

    live_ref = db.reference("/AgriSense/live")
    logger.info("Connected to Firebase RTDB. Streaming simulated ESP32 telemetry every %ss...", interval_seconds)

    # Initial baseline
    temp = 28.5
    humidity = 62.0
    moisture_estimate = 45.0
    uptime_ms = int(time.time() * 1000) % 1000000

    try:
        for i in range(iterations):
            # Realistic physical drift
            temp += random.uniform(-0.3, 0.3)
            temp = max(18.0, min(38.0, round(temp, 1)))

            humidity += random.uniform(-0.8, 0.8)
            humidity = max(30.0, min(85.0, round(humidity, 1)))

            # Moisture slowly drops (simulating plant water consumption)
            moisture_estimate -= random.uniform(0.05, 0.25)
            if moisture_estimate < 15.0:
                # Simulating an irrigation event when it gets very dry
                logger.info("--> Irrigation event simulated! Moisture refreshed.")
                moisture_estimate = 75.0

            moisture_estimate = max(0.0, min(100.0, round(moisture_estimate, 1)))

            # Calibrated ADC
            soil_ao = int(4095 - (moisture_estimate / 100.0) * (4095 - 1400) + random.uniform(-15, 15))
            soil_ao = max(0, min(4095, soil_ao))
            soil_do = 1 if soil_ao > 2800 else 0
            soil_status = "DRY" if moisture_estimate < 30.0 else ("OPTIMAL" if moisture_estimate <= 75.0 else "WET")

            uptime_ms += int(interval_seconds * 1000)
            wifi_rssi = random.choice([-68, -70, -72, -71, -74])

            payload = {
                "dht_valid": True,
                "temperature_c": temp,
                "humidity_percent": humidity,
                "soil_ao_raw": soil_ao,
                "soil_do": soil_do,
                "soil_status": soil_status,
                "soil_adc_range_percent": 100,
                "soil_moisture_estimate_percent": moisture_estimate,
                "wifi_rssi_dbm": wifi_rssi,
                "uptime_ms": uptime_ms,
            }

            live_ref.set(payload)
            logger.info(
                "[%d/%d] Streamed to /AgriSense/live: Temp=%.1f°C, Hum=%.1f%%, Moisture=%.1f%% (%s), ADC=%d",
                i + 1, iterations, temp, humidity, moisture_estimate, soil_status, soil_ao
            )
            time.sleep(interval_seconds)

    except KeyboardInterrupt:
        logger.info("Simulator stopped by user.")

if __name__ == "__main__":
    run_simulator(interval_seconds=3.0, iterations=50)
