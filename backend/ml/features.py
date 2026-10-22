import math
from typing import Dict, Any, List
import pandas as pd
import numpy as np

# Canonical feature list expected by model
FEATURE_NAMES: List[str] = [
    "soil_moisture_estimate_percent",
    "soil_ao_raw",
    "temperature_c",
    "humidity_percent",
    "vpd_kpa",
    "soil_type_code",
    "crop_type_code",
]

SOIL_TYPE_MAPPING = {
    "sand": 0,
    "sandy_loam": 0,
    "loam": 1,
    "silt_loam": 1,
    "clay": 2,
    "clay_loam": 2,
}

CROP_TYPE_MAPPING = {
    "general": 0,
    "wheat": 1,
    "tomato": 2,
    "maize": 3,
    "cotton": 4,
    "rice": 5,
}

def calculate_vpd(temperature_c: float, humidity_percent: float) -> float:
    """
    Calculates Vapor Pressure Deficit (VPD in kPa) using the Tetens equation.
    VPD measures atmospheric drying power and transpiration demand.
    """
    if temperature_c is None or humidity_percent is None:
        return 0.0

    # Saturation vapor pressure (kPa)
    es = 0.61078 * math.exp((17.27 * temperature_c) / (temperature_c + 237.3))
    # Actual vapor pressure (kPa)
    ea = es * (max(0.0, min(100.0, humidity_percent)) / 100.0)
    # VPD is the difference
    vpd = max(0.0, es - ea)
    return round(vpd, 3)

def extract_features_from_reading(
    reading: Dict[str, Any],
    soil_type: str = "loam",
    crop_type: str = "general"
) -> pd.DataFrame:
    """
    Transforms a normalized reading into a 1-row DataFrame aligned with FEATURE_NAMES.
    """
    calibrated = reading.get("calibrated", {})
    raw = reading.get("raw", {})

    temp_c = calibrated.get("temperature_c") or 25.0
    humidity_pct = calibrated.get("humidity_percent") or 50.0
    moisture_pct = calibrated.get("soil_moisture_estimate_percent") or 0.0
    soil_ao = raw.get("soil_ao_raw") or 4095

    vpd = calculate_vpd(temp_c, humidity_pct)
    soil_code = SOIL_TYPE_MAPPING.get(soil_type.lower().strip(), 1)
    crop_code = CROP_TYPE_MAPPING.get(crop_type.lower().strip(), 0)

    data = {
        "soil_moisture_estimate_percent": [float(moisture_pct)],
        "soil_ao_raw": [float(soil_ao)],
        "temperature_c": [float(temp_c)],
        "humidity_percent": [float(humidity_pct)],
        "vpd_kpa": [float(vpd)],
        "soil_type_code": [int(soil_code)],
        "crop_type_code": [int(crop_code)],
    }

    return pd.DataFrame(data)[FEATURE_NAMES]
