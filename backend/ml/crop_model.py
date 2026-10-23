import os
import json
import logging
from typing import Dict, Any, List, Optional
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

logger = logging.getLogger("agrisense.ml.crop")

CROP_PROFILES: Dict[str, Dict[str, Any]] = {
    "rice": {
        "display_name": "Rice (Paddy)",
        "ideal_temp": (20.0, 35.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_ph": (5.5, 7.0),
        "ideal_rainfall": (150.0, 300.0),
        "ideal_soil": "Clayey / Loamy",
        "description": "High water and moisture requirement with submerged or saturated soil conditions.",
        "farmer_tip": "Maintain 2-5 cm standing water during tillering to panicle initiation. Ensure balanced N split doses."
    },
    "maize": {
        "display_name": "Maize (Corn)",
        "ideal_temp": (18.0, 30.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_ph": (5.8, 7.5),
        "ideal_rainfall": (60.0, 110.0),
        "ideal_soil": "Well-drained Loamy / Sandy Loam",
        "description": "Moderately drought tolerant with high nitrogen consumption during knee-high stage.",
        "farmer_tip": "Avoid waterlogging. Apply Nitrogen in 3 splits (basal, knee-high, and tasseling stages)."
    },
    "chickpea": {
        "display_name": "Chickpea (Gram)",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (40.0, 65.0),
        "ideal_ph": (6.0, 8.0),
        "ideal_rainfall": (40.0, 90.0),
        "ideal_soil": "Sandy Loam / Clay Loam",
        "description": "Cool season pulse crop that fixes atmospheric nitrogen; sensitive to excessive moisture.",
        "farmer_tip": "Inoculate seeds with Rhizobium culture. Irrigate once at pre-flowering and pod development."
    },
    "kidneybeans": {
        "display_name": "Kidney Beans (Rajma)",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (50.0, 70.0),
        "ideal_ph": (5.5, 6.8),
        "ideal_rainfall": (60.0, 150.0),
        "ideal_soil": "Rich Loam with good drainage",
        "description": "Demands cool weather and fertile soil with steady moisture.",
        "farmer_tip": "Does not nodulate well; requires higher basal nitrogen fertilizer compared to other pulses."
    },
    "pigeonpeas": {
        "display_name": "Pigeon Peas (Arhar / Tur)",
        "ideal_temp": (20.0, 35.0),
        "ideal_humidity": (45.0, 75.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (60.0, 120.0),
        "ideal_soil": "Deep Loamy / Black Cotton",
        "description": "Deep-rooted drought-resistant pulse crop well suited for dryland farming.",
        "farmer_tip": "Intercrop with sorghum or pearl millet. Prevent collar rot by ensuring proper ridge drainage."
    },
    "mothbeans": {
        "display_name": "Moth Beans",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (30.0, 65.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (30.0, 75.0),
        "ideal_soil": "Sandy / Arid",
        "description": "Extremely drought-hardy legume suitable for arid and semi-arid tracts.",
        "farmer_tip": "Requires minimal irrigation; excel under sandy soils with low organic matter."
    },
    "mungbean": {
        "display_name": "Mung Bean (Green Gram)",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_ph": (6.2, 7.5),
        "ideal_rainfall": (50.0, 90.0),
        "ideal_soil": "Well-drained Loam / Sandy Loam",
        "description": "Short-duration pulse (60-70 days) ideal for summer catch cropping.",
        "farmer_tip": "Spray DAP (2%) at flowering and pod filling for enhanced grain yield."
    },
    "blackgram": {
        "display_name": "Black Gram (Urad)",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_ph": (6.5, 7.8),
        "ideal_rainfall": (60.0, 100.0),
        "ideal_soil": "Heavy Loam / Clay",
        "description": "Hardy legume requiring warm, humid weather and heavy water-retentive soils.",
        "farmer_tip": "Ensure phosphorus application at sowing to stimulate vigorous root nodulation."
    },
    "lentil": {
        "display_name": "Lentil (Masoor)",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (40.0, 80.0),
        "ideal_soil": "Alluvial / Clay Loam",
        "description": "Rabi cool-season legume tolerant to mild frost and dry periods.",
        "farmer_tip": "Provide light irrigation 40 days after sowing. Avoid water stagnation."
    },
    "pomegranate": {
        "display_name": "Pomegranate",
        "ideal_temp": (18.0, 35.0),
        "ideal_humidity": (30.0, 60.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (50.0, 120.0),
        "ideal_soil": "Deep Sandy Loam / Loam",
        "description": "High-value fruit crop adapted to semi-arid climates.",
        "farmer_tip": "Adopt drip irrigation and regulative bahar treatment for uniform fruit size and color."
    },
    "banana": {
        "display_name": "Banana",
        "ideal_temp": (22.0, 36.0),
        "ideal_humidity": (75.0, 95.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (100.0, 200.0),
        "ideal_soil": "Deep, nutrient-rich fertile Loam",
        "description": "Heavy feeder of Nitrogen and Potassium requiring warm tropical humid conditions.",
        "farmer_tip": "Apply high potassium fertilizer during bunch formation and maintain continuous root aeration."
    },
    "mango": {
        "display_name": "Mango",
        "ideal_temp": (24.0, 38.0),
        "ideal_humidity": (45.0, 75.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (75.0, 150.0),
        "ideal_soil": "Well-drained deep Alluvial / Laterite",
        "description": "Tropical fruit requiring a dry period before flowering for optimum bloom.",
        "farmer_tip": "Withhold irrigation 2-3 months prior to flowering to encourage reproductive bud differentiation."
    },
    "grapes": {
        "display_name": "Grapes",
        "ideal_temp": (15.0, 35.0),
        "ideal_humidity": (40.0, 75.0),
        "ideal_ph": (6.5, 8.0),
        "ideal_rainfall": (50.0, 90.0),
        "ideal_soil": "Gravelly / Sandy Loam with caliche drainage",
        "description": "Warm, sunny, dry climate preferred during berry ripening to prevent fungal mildew.",
        "farmer_tip": "Prune carefully in October and April. Implement drip fertigation with micronutrients."
    },
    "watermelon": {
        "display_name": "Watermelon",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (40.0, 80.0),
        "ideal_soil": "Sandy / Sandy Loam",
        "description": "Warm, dry sun-loving cucurbit thriving on riverbed and sandy fields.",
        "farmer_tip": "Mulch soil with plastic to preserve root warmth and reduce fruit rot."
    },
    "muskmelon": {
        "display_name": "Muskmelon",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_ph": (6.0, 7.2),
        "ideal_rainfall": (40.0, 70.0),
        "ideal_soil": "Well-drained Sandy Loam",
        "description": "Requires high heat and low humidity during ripening for high sugar brix.",
        "farmer_tip": "Reduce watering 10 days before harvest to maximize natural sweetness and aroma."
    },
    "apple": {
        "display_name": "Apple",
        "ideal_temp": (10.0, 24.0),
        "ideal_humidity": (55.0, 80.0),
        "ideal_ph": (5.5, 6.8),
        "ideal_rainfall": (90.0, 140.0),
        "ideal_soil": "Well-drained Loamy with high organic matter",
        "description": "Temperate tree crop requiring winter chilling hours (800-1000 hours < 7°C).",
        "farmer_tip": "Maintain clean orchard basins and spray calcium chloride to prevent bitter pit."
    },
    "orange": {
        "display_name": "Orange (Citrus)",
        "ideal_temp": (15.0, 35.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (75.0, 130.0),
        "ideal_soil": "Well-drained Light Loam",
        "description": "Subtropical evergreen citrus requiring well-aerated soil free of high salinity.",
        "farmer_tip": "Apply zinc and iron micronutrient foliar sprays twice a year to prevent chlorosis."
    },
    "papaya": {
        "display_name": "Papaya",
        "ideal_temp": (22.0, 35.0),
        "ideal_humidity": (60.0, 85.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (90.0, 180.0),
        "ideal_soil": "Rich Sandy Loam with excellent drainage",
        "description": "Fast-growing tropical herbaceous plant highly intolerant to waterlogging.",
        "farmer_tip": "Plant on raised mounds to eliminate root stagnation. Protect against papaya ringspot virus."
    },
    "coconut": {
        "display_name": "Coconut",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_ph": (5.2, 8.0),
        "ideal_rainfall": (130.0, 250.0),
        "ideal_soil": "Coastal Sand / Alluvial / Red Loam",
        "description": "Tropical palm flourishing with warm maritime breezes and abundant sunshine.",
        "farmer_tip": "Apply common salt (NaCl) alongside potassium chloride (MOP) to boost nut set and weight."
    },
    "cotton": {
        "display_name": "Cotton",
        "ideal_temp": (21.0, 35.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_ph": (6.0, 8.0),
        "ideal_rainfall": (60.0, 110.0),
        "ideal_soil": "Deep Black Cotton (Regur) / Alluvial",
        "description": "Important commercial fiber crop requiring warm sunny weather during boll maturation.",
        "farmer_tip": "Avoid moisture stress during peak flowering and boll formation. Maintain square retention."
    },
    "jute": {
        "display_name": "Jute",
        "ideal_temp": (24.0, 37.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (150.0, 260.0),
        "ideal_soil": "Alluvial / Loamy Clay",
        "description": "Warm, humid golden fiber crop cultivated in river floodplains.",
        "farmer_tip": "Requires abundant clean running water for post-harvest stem retting and fiber extraction."
    },
    "coffee": {
        "display_name": "Coffee",
        "ideal_temp": (18.0, 28.0),
        "ideal_humidity": (65.0, 85.0),
        "ideal_ph": (5.5, 6.5),
        "ideal_rainfall": (120.0, 220.0),
        "ideal_soil": "Rich volcanic / Forest Humus Loam",
        "description": "Shade-tolerant plantation crop thriving in gentle highland climates.",
        "farmer_tip": "Provide 50% canopy shade trees (Silver Oak / Albizia) to buffer heat and regulate blossom."
    }
}


class CropPredictor:
    """Predicts optimal crop suited for soil and environmental parameters using Kaggle ML model."""

    FEATURE_NAMES = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]

    def __init__(self, model_path: str, data_path: Optional[str] = None):
        self.model_path = model_path
        self.data_path = data_path or os.path.join(
            os.path.dirname(__file__), "data", "crop_recommendation.csv"
        )
        self.model = None
        self.is_loaded = False
        self._load_or_train()

    def _load_or_train(self):
        """Loads trained model or trains if absent."""
        if os.path.exists(self.model_path):
            try:
                self.model = joblib.load(self.model_path)
                self.is_loaded = True
                logger.info("Loaded Crop model from: %s", self.model_path)
                return
            except Exception as e:
                logger.warning("Failed to load Crop model from %s: %s. Retraining...", self.model_path, e)

        # Train model if dataset is available
        if os.path.exists(self.data_path):
            try:
                self.train_and_save()
            except Exception as e:
                logger.error("Failed to train Crop model: %s", e)
                self.is_loaded = False
        else:
            logger.warning("Crop dataset not found at: %s", self.data_path)
            self.is_loaded = False

    def train_and_save(self) -> float:
        """Trains RandomForest on Crop Recommendation dataset and saves joblib artifact."""
        logger.info("Training Crop Recommendation Model on %s...", self.data_path)
        df = pd.read_csv(self.data_path)
        X = df[self.FEATURE_NAMES]
        y = df["label"]

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        model = RandomForestClassifier(
            n_estimators=100,
            max_depth=16,
            random_state=42,
            n_jobs=-1
        )
        model.fit(X_train, y_train)

        acc = float(accuracy_score(y_test, model.predict(X_test)))
        logger.info("Crop Model Accuracy: %.4f", acc)

        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        joblib.dump(model, self.model_path)
        self.model = model
        self.is_loaded = True
        return acc

    def predict(
        self,
        nitrogen: float,
        phosphorus: float,
        potassium: float,
        temperature_c: float,
        humidity_percent: float,
        ph: float,
        rainfall_mm: float = 100.0,
    ) -> Dict[str, Any]:
        """
        Predicts the top suited crop and alternatives.
        """
        sample_df = pd.DataFrame([{
            "N": float(nitrogen),
            "P": float(phosphorus),
            "K": float(potassium),
            "temperature": float(temperature_c),
            "humidity": float(humidity_percent),
            "ph": float(ph),
            "rainfall": float(rainfall_mm),
        }])[self.FEATURE_NAMES]

        if not self.is_loaded or self.model is None:
            # Fallback to nearest heuristic
            return self._fallback_prediction(
                nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm
            )

        try:
            pred_crop = str(self.model.predict(sample_df)[0]).lower()
            probs = self.model.predict_proba(sample_df)[0]
            classes = self.model.classes_

            # Sort top classes by probability
            top_indices = np.argsort(probs)[::-1]
            top_prob = float(probs[top_indices[0]])

            alternatives: List[Dict[str, Any]] = []
            for idx in top_indices[1:4]:
                crop_name = str(classes[idx]).lower()
                alt_prob = float(probs[idx])
                if alt_prob > 0.05:  # Only report realistic alternatives
                    profile = CROP_PROFILES.get(crop_name, {})
                    alternatives.append({
                        "crop": crop_name,
                        "display_name": profile.get("display_name", crop_name.capitalize()),
                        "suitability_percent": round(alt_prob * 100, 1),
                        "farmer_tip": profile.get("farmer_tip", ""),
                    })

            profile = CROP_PROFILES.get(pred_crop, {})
            display_name = profile.get("display_name", pred_crop.capitalize())

            # Evaluate suitability factors
            factors = self._evaluate_factors(
                pred_crop, nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm
            )

            return {
                "available": True,
                "recommended_crop": pred_crop,
                "display_name": display_name,
                "confidence": round(top_prob, 3),
                "suitability_percent": round(top_prob * 100, 1),
                "description": profile.get("description", "Agronomically suited crop for this land."),
                "farmer_tip": profile.get("farmer_tip", "Ensure recommended soil preparation and timely sowing."),
                "ideal_soil": profile.get("ideal_soil", "Loamy / Well-drained"),
                "alternatives": alternatives,
                "factors_analysis": factors,
                "inputs": {
                    "nitrogen": round(float(nitrogen), 1),
                    "phosphorus": round(float(phosphorus), 1),
                    "potassium": round(float(potassium), 1),
                    "temperature_c": round(float(temperature_c), 1),
                    "humidity_percent": round(float(humidity_percent), 1),
                    "ph": round(float(ph), 2),
                    "rainfall_mm": round(float(rainfall_mm), 1),
                }
            }
        except Exception as e:
            logger.error("Error during crop inference: %s", e)
            return self._fallback_prediction(
                nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm
            )

    def _evaluate_factors(
        self,
        crop: str,
        n: float, p: float, k: float, temp: float, hum: float, ph: float, rain: float
    ) -> List[Dict[str, Any]]:
        """Generates detailed farmer-friendly factor ratings."""
        profile = CROP_PROFILES.get(crop, {})
        factors = []

        # Temperature
        t_min, t_max = profile.get("ideal_temp", (18.0, 32.0))
        t_ok = t_min <= temp <= t_max
        factors.append({
            "parameter": "Temperature",
            "current": f"{temp:.1f} °C",
            "ideal_range": f"{t_min:.0f} - {t_max:.0f} °C",
            "status": "OPTIMAL" if t_ok else ("HIGH" if temp > t_max else "LOW"),
            "is_favorable": t_ok,
        })

        # Humidity
        h_min, h_max = profile.get("ideal_humidity", (50.0, 80.0))
        h_ok = h_min <= hum <= h_max
        factors.append({
            "parameter": "Relative Humidity",
            "current": f"{hum:.1f} %",
            "ideal_range": f"{h_min:.0f} - {h_max:.0f} %",
            "status": "OPTIMAL" if h_ok else ("HIGH" if hum > h_max else "LOW"),
            "is_favorable": h_ok,
        })

        # Soil pH
        ph_min, ph_max = profile.get("ideal_ph", (6.0, 7.5))
        ph_ok = ph_min <= ph <= ph_max
        factors.append({
            "parameter": "Soil pH",
            "current": f"{ph:.2f}",
            "ideal_range": f"{ph_min:.1f} - {ph_max:.1f}",
            "status": "OPTIMAL" if ph_ok else ("ALKALINE" if ph > ph_max else "ACIDIC"),
            "is_favorable": ph_ok,
        })

        # Soil Nutrients
        n_status = "ADEQUATE" if n >= 40 else ("LOW" if n < 25 else "MODERATE")
        factors.append({
            "parameter": "Soil Nitrogen (N)",
            "current": f"{n:.0f} kg/ha",
            "ideal_range": "> 40 kg/ha",
            "status": n_status,
            "is_favorable": n >= 30,
        })

        return factors

    def _fallback_prediction(
        self, n: float, p: float, k: float, temp: float, hum: float, ph: float, rain: float
    ) -> Dict[str, Any]:
        """Agronomic rule-based fallback when ML artifact is uninitialized."""
        if temp > 22 and hum > 70 and rain > 150:
            pred = "rice"
        elif temp > 20 and n > 45:
            pred = "maize"
        elif temp < 22:
            pred = "wheat"
        else:
            pred = "cotton"

        profile = CROP_PROFILES.get(pred, {})
        return {
            "available": True,
            "recommended_crop": pred,
            "display_name": profile.get("display_name", pred.capitalize()),
            "confidence": 0.85,
            "suitability_percent": 85.0,
            "description": profile.get("description", "Recommended by agronomic rule engine."),
            "farmer_tip": profile.get("farmer_tip", "Ensure balanced basal fertilizer application."),
            "ideal_soil": profile.get("ideal_soil", "Loamy"),
            "alternatives": [],
            "factors_analysis": self._evaluate_factors(pred, n, p, k, temp, hum, ph, rain),
            "inputs": {
                "nitrogen": round(float(n), 1),
                "phosphorus": round(float(p), 1),
                "potassium": round(float(k), 1),
                "temperature_c": round(float(temp), 1),
                "humidity_percent": round(float(hum), 1),
                "ph": round(float(ph), 2),
                "rainfall_mm": round(float(rain), 1),
            }
        }
