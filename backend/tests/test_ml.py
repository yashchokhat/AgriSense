import pytest
import os
from backend.ml.features import calculate_vpd, extract_features_from_reading, FEATURE_NAMES
from backend.ml.predict import IrrigationPredictor
from backend.services.recommendation_service import RecommendationService
from backend.services.sensor_service import SensorService

def test_calculate_vpd():
    # 25°C and 50% RH -> es ~ 3.167 kPa, ea ~ 1.583 kPa -> VPD ~ 1.58 kPa
    vpd = calculate_vpd(25.0, 50.0)
    assert 1.4 < vpd < 1.7

    # 100% RH -> VPD must be 0
    assert calculate_vpd(25.0, 100.0) == 0.0

def test_extract_features_schema(sample_raw_reading):
    sensor_svc = SensorService()
    normalized, _ = sensor_svc.validate_and_normalize(sample_raw_reading)

    df = extract_features_from_reading(normalized, soil_type="loam", crop_type="tomato")
    assert list(df.columns) == FEATURE_NAMES
    assert len(df) == 1
    assert df["soil_type_code"].iloc[0] == 1
    assert df["crop_type_code"].iloc[0] == 2

def test_ml_predictor_inference(sample_raw_reading):
    sensor_svc = SensorService()
    normalized, _ = sensor_svc.validate_and_normalize(sample_raw_reading)

    model_path = "backend/ml/models/irrigation_model.joblib"
    meta_path = "backend/ml/models/model_metadata.json"

    predictor = IrrigationPredictor(model_path, meta_path)
    assert predictor.is_loaded is True

    result = predictor.predict(normalized, crop_type="wheat", soil_type="loam")
    assert result["available"] is True
    assert isinstance(result["irrigation_needed"], bool)
    assert 0.0 <= result["confidence"] <= 1.0
    assert len(result["explanation"]) >= 1

def test_ml_predictor_missing_model(sample_raw_reading):
    sensor_svc = SensorService()
    normalized, _ = sensor_svc.validate_and_normalize(sample_raw_reading)

    predictor = IrrigationPredictor("nonexistent_model.joblib", "nonexistent_meta.json")
    assert predictor.is_loaded is False

    result = predictor.predict(normalized)
    assert result["available"] is False
    assert result["error"] == "MODEL_UNAVAILABLE"

def test_recommendation_fallback_rule(sample_raw_reading):
    sensor_svc = SensorService()
    # When soil_status is DRY, it triggers CRITICAL urgency
    normalized, _ = sensor_svc.validate_and_normalize(sample_raw_reading)

    predictor = IrrigationPredictor("none.joblib", "none.json")
    rec_svc = RecommendationService(predictor, critical_low_threshold=25.0, optimal_min_threshold=40.0)

    rec = rec_svc.get_recommendation(normalized, crop_type="wheat", soil_type="loam")

    assert rec["available"] is True
    assert rec["is_ml_based"] is False
    assert rec["recommendation_type"] == "threshold_rule"
    assert rec["irrigation_needed"] is True
    assert rec["urgency"] == "CRITICAL"

    # When soil_status is OPTIMAL and moisture is 35% (between 25% and 40%), urgency is MODERATE
    sample_raw_reading["soil_status"] = "OPTIMAL"
    sample_raw_reading["soil_moisture_estimate_percent"] = 35.0
    norm2, _ = sensor_svc.validate_and_normalize(sample_raw_reading)
    rec2 = rec_svc.get_recommendation(norm2, crop_type="wheat", soil_type="loam")
    assert rec2["urgency"] == "MODERATE"
