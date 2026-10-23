import pytest
from backend.app import create_app
from backend.ml.crop_model import CropPredictor
from backend.ml.fertilizer_model import FertilizerPredictor
from backend.services.agronomy_service import AgronomyService


@pytest.fixture
def app():
    app = create_app()
    app.config.update({"TESTING": True})
    return app


@pytest.fixture
def client(app):
    return app.test_client()


def test_crop_predictor_inference():
    predictor = CropPredictor(model_path="backend/ml/models/crop_model.joblib")
    # High rainfall, warm, humid -> rice conditions
    result = predictor.predict(
        nitrogen=90,
        phosphorus=42,
        potassium=43,
        temperature_c=25.0,
        humidity_percent=82.0,
        ph=6.5,
        rainfall_mm=220.0
    )
    assert result["available"] is True
    assert result["recommended_crop"] == "rice"
    assert "suitability_percent" in result
    assert result["confidence"] > 0.5
    assert len(result["factors_analysis"]) > 0


def test_fertilizer_predictor_inference():
    predictor = FertilizerPredictor(model_path="backend/ml/models/fertilizer_model.joblib")
    # Low nitrogen -> Urea
    result = predictor.predict(
        temperature_c=28.0,
        humidity_percent=54.0,
        moisture_percent=46.0,
        nitrogen=35.0,
        potassium=0.0,
        phosphorus=0.0,
        soil_type="Clayey",
        crop_type="Paddy",
    )
    assert result["available"] is True
    assert result["recommended_fertilizer"] == "Urea"
    assert "recommended_dosage" in result
    assert "deficiency_analysis" in result


def test_agronomy_service_defaults_and_updates():
    crop_p = CropPredictor(model_path="backend/ml/models/crop_model.joblib")
    fert_p = FertilizerPredictor(model_path="backend/ml/models/fertilizer_model.joblib")
    service = AgronomyService(crop_p, fert_p)
    service.reset_soil_profile()

    defaults = service.get_soil_profile()
    assert defaults["nitrogen"] == 50.0
    assert defaults["ph"] == 6.5
    assert defaults["is_manually_entered"] is False

    updated = service.update_soil_profile({
        "nitrogen": 75.0,
        "phosphorus": 35.0,
        "potassium": 45.0,
        "ph": 7.2,
        "soil_type": "Black",
        "target_crop": "Cotton"
    })
    assert updated["nitrogen"] == 75.0
    assert updated["ph"] == 7.2
    assert updated["soil_type"] == "Black"
    assert updated["target_crop"] == "Cotton"
    assert updated["is_manually_entered"] is True

    reset = service.reset_soil_profile()
    assert reset["nitrogen"] == 50.0
    assert reset["is_manually_entered"] is False


def test_agronomy_api_endpoints(client):
    if hasattr(client.application, "agronomy_service"):
        client.application.agronomy_service.reset_soil_profile()

    # 1. Soil Profile GET
    res = client.get("/api/v1/recommendations/soil-profile")
    assert res.status_code == 200
    data = res.get_json()["data"]
    assert data["nitrogen"] == 50.0
    assert data["ph"] == 6.5

    # 2. Soil Profile POST (Farmer input)
    res = client.post("/api/v1/recommendations/soil-profile", json={
        "nitrogen": 80.0,
        "phosphorus": 45.0,
        "potassium": 50.0,
        "ph": 6.8,
        "rainfall_mm": 120.0,
        "soil_type": "Sandy Loam",
        "target_crop": "Maize"
    })
    assert res.status_code == 200
    assert res.get_json()["data"]["nitrogen"] == 80.0
    assert res.get_json()["data"]["is_manually_entered"] is True

    # 3. Agronomy Advisory GET
    res = client.get("/api/v1/recommendations/agronomy")
    assert res.status_code == 200
    advisory = res.get_json()["data"]
    assert "crop_recommendation" in advisory
    assert "fertilizer_recommendation" in advisory
    assert "environment" in advisory
    assert advisory["crop_recommendation"]["available"] is True
    assert advisory["fertilizer_recommendation"]["available"] is True

    # 4. Crop prediction POST
    res = client.post("/api/v1/recommendations/crop", json={
        "nitrogen": 90,
        "phosphorus": 42,
        "potassium": 43,
        "temperature_c": 24,
        "humidity_percent": 80,
        "ph": 6.5,
        "rainfall_mm": 200
    })
    assert res.status_code == 200
    assert res.get_json()["data"]["recommended_crop"] == "rice"

    # 5. Fertilizer prediction POST
    res = client.post("/api/v1/recommendations/fertilizer", json={
        "temperature_c": 26,
        "humidity_percent": 52,
        "moisture_percent": 38,
        "nitrogen": 37,
        "potassium": 0,
        "phosphorus": 0,
        "soil_type": "Sandy",
        "crop_type": "Maize"
    })
    assert res.status_code == 200
    assert res.get_json()["data"]["recommended_fertilizer"] == "Urea"

    # 6. Dashboard contains agronomy summary
    res = client.get("/api/v1/dashboard")
    assert res.status_code == 200
    dashboard = res.get_json()["data"]
    assert "agronomy" in dashboard
    assert dashboard["agronomy"] is not None
    assert "crop_recommendation" in dashboard["agronomy"]
