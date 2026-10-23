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
    # Cereals & Grains
    "rice": {
        "display_name": "Rice (Paddy)",
        "category": "Cereal & Grain",
        "ideal_temp": (20.0, 35.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_moisture": (65.0, 95.0),
        "ideal_ph": (5.5, 7.0),
        "ideal_rainfall": (150.0, 300.0),
        "ideal_soil": "Clayey / Loamy",
        "description": "High water and moisture requirement with submerged or saturated soil conditions.",
        "farmer_tip": "Maintain 2-5 cm standing water during tillering to panicle initiation. Ensure balanced N split doses."
    },
    "wheat": {
        "display_name": "Wheat",
        "category": "Cereal & Grain",
        "ideal_temp": (12.0, 25.0),
        "ideal_humidity": (50.0, 70.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (50.0, 100.0),
        "ideal_soil": "Well-drained fertile Loam / Clay Loam",
        "description": "Premier rabi staple cereal thriving in cool vegetative weather and warm sunny grain filling.",
        "farmer_tip": "Provide crown root initiation (CRI) irrigation 21 days after sowing. Top-dress Urea at first irrigation."
    },
    "barley": {
        "display_name": "Barley",
        "category": "Cereal & Grain",
        "ideal_temp": (12.0, 22.0),
        "ideal_humidity": (35.0, 60.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.5, 8.2),
        "ideal_rainfall": (35.0, 75.0),
        "ideal_soil": "Sandy Loam / Light Clay with alkaline tolerance",
        "description": "Hardy cereal highly tolerant to salinity, alkalinity, and moisture stress.",
        "farmer_tip": "Excellent choice for semi-arid saline soils where wheat struggles. Avoid excessive nitrogen lodging."
    },
    "maize": {
        "display_name": "Maize (Corn)",
        "category": "Cereal & Grain",
        "ideal_temp": (18.0, 30.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_moisture": (45.0, 75.0),
        "ideal_ph": (5.8, 7.5),
        "ideal_rainfall": (60.0, 110.0),
        "ideal_soil": "Well-drained Loamy / Sandy Loam",
        "description": "Moderately drought tolerant with high nitrogen consumption during knee-high stage.",
        "farmer_tip": "Avoid waterlogging. Apply Nitrogen in 3 splits (basal, knee-high, and tasseling stages)."
    },

    # Pulses & Legumes
    "chickpea": {
        "display_name": "Chickpea (Gram)",
        "category": "Pulse & Legume",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (40.0, 65.0),
        "ideal_moisture": (25.0, 50.0),
        "ideal_ph": (6.0, 8.0),
        "ideal_rainfall": (40.0, 90.0),
        "ideal_soil": "Sandy Loam / Clay Loam",
        "description": "Cool season pulse crop that fixes atmospheric nitrogen; sensitive to excessive moisture.",
        "farmer_tip": "Inoculate seeds with Rhizobium culture. Irrigate once at pre-flowering and pod development."
    },
    "kidneybeans": {
        "display_name": "Kidney Beans (Rajma)",
        "category": "Pulse & Legume",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (50.0, 70.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (5.5, 6.8),
        "ideal_rainfall": (60.0, 150.0),
        "ideal_soil": "Rich Loam with good drainage",
        "description": "Demands cool weather and fertile soil with steady moisture.",
        "farmer_tip": "Does not nodulate well; requires higher basal nitrogen fertilizer compared to other pulses."
    },
    "pigeonpeas": {
        "display_name": "Pigeon Peas (Arhar / Tur)",
        "category": "Pulse & Legume",
        "ideal_temp": (20.0, 35.0),
        "ideal_humidity": (45.0, 75.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (60.0, 120.0),
        "ideal_soil": "Deep Loamy / Black Cotton",
        "description": "Deep-rooted drought-resistant pulse crop well suited for dryland farming.",
        "farmer_tip": "Intercrop with sorghum or pearl millet. Prevent collar rot by ensuring proper ridge drainage."
    },
    "mothbeans": {
        "display_name": "Moth Beans",
        "category": "Pulse & Legume",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (30.0, 65.0),
        "ideal_moisture": (20.0, 45.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (30.0, 75.0),
        "ideal_soil": "Sandy / Arid",
        "description": "Extremely drought-hardy legume suitable for arid and semi-arid tracts.",
        "farmer_tip": "Requires minimal irrigation; excel under sandy soils with low organic matter."
    },
    "mungbean": {
        "display_name": "Mung Bean (Green Gram)",
        "category": "Pulse & Legume",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (6.2, 7.5),
        "ideal_rainfall": (50.0, 90.0),
        "ideal_soil": "Well-drained Loam / Sandy Loam",
        "description": "Short-duration pulse (60-70 days) ideal for summer catch cropping.",
        "farmer_tip": "Spray DAP (2%) at flowering and pod filling for enhanced grain yield."
    },
    "blackgram": {
        "display_name": "Black Gram (Urad)",
        "category": "Pulse & Legume",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (6.5, 7.8),
        "ideal_rainfall": (60.0, 100.0),
        "ideal_soil": "Heavy Loam / Clay",
        "description": "Hardy legume requiring warm, humid weather and heavy water-retentive soils.",
        "farmer_tip": "Ensure phosphorus application at sowing to stimulate vigorous root nodulation."
    },
    "lentil": {
        "display_name": "Lentil (Masoor)",
        "category": "Pulse & Legume",
        "ideal_temp": (15.0, 25.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (25.0, 50.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (40.0, 80.0),
        "ideal_soil": "Alluvial / Clay Loam",
        "description": "Rabi cool-season legume tolerant to mild frost and dry periods.",
        "farmer_tip": "Provide light irrigation 40 days after sowing. Avoid water stagnation."
    },
    "soybean": {
        "display_name": "Soybean",
        "category": "Pulse & Legume",
        "ideal_temp": (20.0, 32.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_moisture": (50.0, 75.0),
        "ideal_ph": (6.0, 7.2),
        "ideal_rainfall": (65.0, 120.0),
        "ideal_soil": "Deep fertile Loam with organic matter",
        "description": "High-protein legume and oilseed crop that enriches soil through biological nitrogen fixation.",
        "farmer_tip": "Treat seed with Bradyrhizobium culture. Ensure good drainage; avoid waterlogging during germination."
    },

    # Oilseeds
    "groundnut": {
        "display_name": "Groundnut (Peanut)",
        "category": "Oilseed",
        "ideal_temp": (22.0, 34.0),
        "ideal_humidity": (50.0, 70.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (5.8, 7.2),
        "ideal_rainfall": (50.0, 95.0),
        "ideal_soil": "Well-aerated Sandy Loam / Red Sandy",
        "description": "Subterranean pod-forming legume requiring light, friable soils for easy peg penetration.",
        "farmer_tip": "Apply Gypsum (200 kg/acre) at flowering/pegging stage to supply calcium for well-filled pods."
    },
    "mustard": {
        "display_name": "Mustard (Rape)",
        "category": "Oilseed",
        "ideal_temp": (12.0, 25.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (35.0, 70.0),
        "ideal_soil": "Alluvial / Loamy Sand",
        "description": "Major winter oilseed crop with bright yellow blooms and low water requirement.",
        "farmer_tip": "Apply Sulphur (20 kg/ha) alongside balanced NPK to significantly raise oil content and pungency."
    },
    "sunflower": {
        "display_name": "Sunflower",
        "category": "Oilseed",
        "ideal_temp": (18.0, 32.0),
        "ideal_humidity": (40.0, 65.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (6.2, 7.5),
        "ideal_rainfall": (45.0, 90.0),
        "ideal_soil": "Deep Loam / Black Cotton / Sandy Loam",
        "description": "Photo-insensitive, drought-hardy oilseed adaptable across multiple seasons.",
        "farmer_tip": "Maintain bee hives near the field during morning flowering hours to ensure complete seed set."
    },

    # Cash & Commercial Crops
    "cotton": {
        "display_name": "Cotton",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (21.0, 35.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (6.0, 8.0),
        "ideal_rainfall": (60.0, 110.0),
        "ideal_soil": "Deep Black Cotton (Regur) / Alluvial",
        "description": "Important commercial fiber crop requiring warm sunny weather during boll maturation.",
        "farmer_tip": "Avoid moisture stress during peak flowering and boll formation. Maintain square retention."
    },
    "jute": {
        "display_name": "Jute",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (24.0, 37.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_moisture": (65.0, 90.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (150.0, 260.0),
        "ideal_soil": "Alluvial / Loamy Clay",
        "description": "Warm, humid golden fiber crop cultivated in river floodplains.",
        "farmer_tip": "Requires abundant clean running water for post-harvest stem retting and fiber extraction."
    },
    "sugarcane": {
        "display_name": "Sugarcane",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (24.0, 38.0),
        "ideal_humidity": (65.0, 88.0),
        "ideal_moisture": (65.0, 90.0),
        "ideal_ph": (6.0, 7.8),
        "ideal_rainfall": (140.0, 260.0),
        "ideal_soil": "Deep, well-drained rich Alluvial / Clay Loam",
        "description": "High-biomass perennial grass demanding generous moisture, heat, and nutrition.",
        "farmer_tip": "Adopt trash mulching to conserve moisture. Apply potash during tillering to elevate sucrose content."
    },
    "coffee": {
        "display_name": "Coffee",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (18.0, 28.0),
        "ideal_humidity": (65.0, 85.0),
        "ideal_moisture": (50.0, 75.0),
        "ideal_ph": (5.5, 6.5),
        "ideal_rainfall": (120.0, 220.0),
        "ideal_soil": "Rich volcanic / Forest Humus Loam",
        "description": "Shade-tolerant plantation crop thriving in gentle highland climates.",
        "farmer_tip": "Provide 50% canopy shade trees (Silver Oak / Albizia) to buffer heat and regulate blossom."
    },
    "tea": {
        "display_name": "Tea",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (15.0, 28.0),
        "ideal_humidity": (70.0, 92.0),
        "ideal_moisture": (60.0, 85.0),
        "ideal_ph": (4.5, 5.8),
        "ideal_rainfall": (150.0, 280.0),
        "ideal_soil": "Acidic forest humus / Lateritic Loam",
        "description": "Highland evergreen shrub yielding tender young flushes under misty humid conditions.",
        "farmer_tip": "Ensure soil pH stays strictly below 5.8. Provide gentle terracing and shade trees (Grevillea)."
    },
    "coconut": {
        "display_name": "Coconut",
        "category": "Cash Crop / Commercial",
        "ideal_temp": (25.0, 35.0),
        "ideal_humidity": (70.0, 95.0),
        "ideal_moisture": (55.0, 80.0),
        "ideal_ph": (5.2, 8.0),
        "ideal_rainfall": (130.0, 250.0),
        "ideal_soil": "Coastal Sand / Alluvial / Red Loam",
        "description": "Tropical palm flourishing with warm maritime breezes and abundant sunshine.",
        "farmer_tip": "Apply common salt (NaCl) alongside potassium chloride (MOP) to boost nut set and weight."
    },

    # Vegetables & Spices
    "potato": {
        "display_name": "Potato",
        "category": "Vegetable & Spice",
        "ideal_temp": (14.0, 24.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_moisture": (55.0, 75.0),
        "ideal_ph": (5.0, 6.5),
        "ideal_rainfall": (60.0, 110.0),
        "ideal_soil": "Loose, friable Sandy Loam with rich compost",
        "description": "Cool-season tuber requiring friable well-aerated soil for tuber expansion and breathing.",
        "farmer_tip": "Perform earthing up 30-35 days after planting. Ensure potash is supplied to prevent hollow heart."
    },
    "tomato": {
        "display_name": "Tomato",
        "category": "Vegetable & Spice",
        "ideal_temp": (18.0, 30.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_moisture": (45.0, 70.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (50.0, 90.0),
        "ideal_soil": "Fertile Loam with good drainage",
        "description": "Warm-season solanaceous vegetable sensitive to severe frost and continuous rain at bloom.",
        "farmer_tip": "Stake indeterminate vines. Spray Calcium nitrate to prevent blossom end rot in developing fruits."
    },
    "onion": {
        "display_name": "Onion",
        "category": "Vegetable & Spice",
        "ideal_temp": (15.0, 28.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (6.0, 7.2),
        "ideal_rainfall": (40.0, 80.0),
        "ideal_soil": "Rich Sandy Loam / Silt Loam free of stones",
        "description": "Shallow-rooted bulb vegetable requiring uniform moisture and weed-free loose beds.",
        "farmer_tip": "Stop watering 10-15 days before harvest when tops begin to bend for superior storage curing."
    },
    "garlic": {
        "display_name": "Garlic",
        "category": "Vegetable & Spice",
        "ideal_temp": (12.0, 24.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (35.0, 75.0),
        "ideal_soil": "Fertile Sandy Loam with organic mulch",
        "description": "Aromatic allium crop requiring cool winters for clove splitting and warm sunny bulb maturity.",
        "farmer_tip": "Plant cloves pointing upright at 10x10 cm spacing. Mulch with straw to control weeds and conserve moisture."
    },

    # Fruits
    "apple": {
        "display_name": "Apple",
        "category": "Fruit",
        "ideal_temp": (10.0, 24.0),
        "ideal_humidity": (55.0, 80.0),
        "ideal_moisture": (45.0, 70.0),
        "ideal_ph": (5.5, 6.8),
        "ideal_rainfall": (90.0, 140.0),
        "ideal_soil": "Well-drained Loamy with high organic matter",
        "description": "Temperate tree crop requiring winter chilling hours (800-1000 hours < 7°C).",
        "farmer_tip": "Maintain clean orchard basins and spray calcium chloride to prevent bitter pit."
    },
    "banana": {
        "display_name": "Banana",
        "category": "Fruit",
        "ideal_temp": (22.0, 36.0),
        "ideal_humidity": (75.0, 95.0),
        "ideal_moisture": (60.0, 85.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (100.0, 200.0),
        "ideal_soil": "Deep, nutrient-rich fertile Loam",
        "description": "Heavy feeder of Nitrogen and Potassium requiring warm tropical humid conditions.",
        "farmer_tip": "Apply high potassium fertilizer during bunch formation and maintain continuous root aeration."
    },
    "mango": {
        "display_name": "Mango",
        "category": "Fruit",
        "ideal_temp": (24.0, 38.0),
        "ideal_humidity": (45.0, 75.0),
        "ideal_moisture": (35.0, 60.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (75.0, 150.0),
        "ideal_soil": "Well-drained deep Alluvial / Laterite",
        "description": "Tropical fruit requiring a dry period before flowering for optimum bloom.",
        "farmer_tip": "Withhold irrigation 2-3 months prior to flowering to encourage reproductive bud differentiation."
    },
    "grapes": {
        "display_name": "Grapes",
        "category": "Fruit",
        "ideal_temp": (15.0, 35.0),
        "ideal_humidity": (40.0, 75.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.5, 8.0),
        "ideal_rainfall": (50.0, 90.0),
        "ideal_soil": "Gravelly / Sandy Loam with caliche drainage",
        "description": "Warm, sunny, dry climate preferred during berry ripening to prevent fungal mildew.",
        "farmer_tip": "Prune carefully in October and April. Implement drip fertigation with micronutrients."
    },
    "watermelon": {
        "display_name": "Watermelon",
        "category": "Fruit",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (40.0, 80.0),
        "ideal_soil": "Sandy / Sandy Loam",
        "description": "Warm, dry sun-loving cucurbit thriving on riverbed and sandy fields.",
        "farmer_tip": "Mulch soil with plastic to preserve root warmth and reduce fruit rot."
    },
    "muskmelon": {
        "display_name": "Muskmelon",
        "category": "Fruit",
        "ideal_temp": (24.0, 35.0),
        "ideal_humidity": (45.0, 65.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.0, 7.2),
        "ideal_rainfall": (40.0, 70.0),
        "ideal_soil": "Well-drained Sandy Loam",
        "description": "Requires high heat and low humidity during ripening for high sugar brix.",
        "farmer_tip": "Reduce watering 10 days before harvest to maximize natural sweetness and aroma."
    },
    "orange": {
        "display_name": "Orange (Citrus)",
        "category": "Fruit",
        "ideal_temp": (15.0, 35.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (75.0, 130.0),
        "ideal_soil": "Well-drained Light Loam",
        "description": "Subtropical evergreen citrus requiring well-aerated soil free of high salinity.",
        "farmer_tip": "Apply zinc and iron micronutrient foliar sprays twice a year to prevent chlorosis."
    },
    "papaya": {
        "display_name": "Papaya",
        "category": "Fruit",
        "ideal_temp": (22.0, 35.0),
        "ideal_humidity": (60.0, 85.0),
        "ideal_moisture": (50.0, 75.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (90.0, 180.0),
        "ideal_soil": "Rich Sandy Loam with excellent drainage",
        "description": "Fast-growing tropical herbaceous plant highly intolerant to waterlogging.",
        "farmer_tip": "Plant on raised mounds to eliminate root stagnation. Protect against papaya ringspot virus."
    },
    "pomegranate": {
        "display_name": "Pomegranate",
        "category": "Fruit",
        "ideal_temp": (18.0, 35.0),
        "ideal_humidity": (30.0, 60.0),
        "ideal_moisture": (30.0, 55.0),
        "ideal_ph": (6.0, 7.5),
        "ideal_rainfall": (50.0, 120.0),
        "ideal_soil": "Deep Sandy Loam / Loam",
        "description": "High-value fruit crop adapted to semi-arid climates.",
        "farmer_tip": "Adopt drip irrigation and regulative bahar treatment for uniform fruit size and color."
    },
    "strawberry": {
        "display_name": "Strawberry",
        "category": "Fruit",
        "ideal_temp": (12.0, 22.0),
        "ideal_humidity": (60.0, 75.0),
        "ideal_moisture": (50.0, 70.0),
        "ideal_ph": (5.5, 6.8),
        "ideal_rainfall": (60.0, 100.0),
        "ideal_soil": "Rich Sandy Loam with heavy organic manure",
        "description": "High-value berry requiring cool sunny days, mild nights, and raised bed cultivation.",
        "farmer_tip": "Plant on raised ridges covered with black plastic mulch. Install drip fertigation with potassium."
    },
    "pineapple": {
        "display_name": "Pineapple",
        "category": "Fruit",
        "ideal_temp": (22.0, 34.0),
        "ideal_humidity": (70.0, 85.0),
        "ideal_moisture": (45.0, 70.0),
        "ideal_ph": (4.5, 6.0),
        "ideal_rainfall": (100.0, 180.0),
        "ideal_soil": "Acidic Sandy Loam with excellent percolation",
        "description": "Bromeliad tropical fruit possessing excellent drought tolerance and acidic soil preference.",
        "farmer_tip": "Apply Ethrel (25 ppm) at 35-leaf stage to induce uniform synchronized flowering and harvest."
    },
    "guava": {
        "display_name": "Guava",
        "category": "Fruit",
        "ideal_temp": (20.0, 35.0),
        "ideal_humidity": (45.0, 70.0),
        "ideal_moisture": (35.0, 65.0),
        "ideal_ph": (5.5, 7.5),
        "ideal_rainfall": (50.0, 110.0),
        "ideal_soil": "Alluvial / Deep Loam / Red Sandy",
        "description": "Exceptionally hardy tropical fruit rich in Vitamin C, tolerant to droughts and mild salinity.",
        "farmer_tip": "Prune branch tips in May to stimulate productive lateral shoots for the winter (Mrig bahar) crop."
    },
    "lemon": {
        "display_name": "Lemon (Citrus)",
        "category": "Fruit",
        "ideal_temp": (18.0, 32.0),
        "ideal_humidity": (45.0, 70.0),
        "ideal_moisture": (40.0, 65.0),
        "ideal_ph": (5.8, 7.5),
        "ideal_rainfall": (55.0, 100.0),
        "ideal_soil": "Well-drained light Loam / Alluvial",
        "description": "Evergreen acid citrus providing continuous flushes under sunny frost-free conditions.",
        "farmer_tip": "Apply copper oxychloride spray before monsoon to protect against citrus canker and twig dieback."
    },
    "avocado": {
        "display_name": "Avocado",
        "category": "Fruit",
        "ideal_temp": (16.0, 28.0),
        "ideal_humidity": (50.0, 75.0),
        "ideal_moisture": (50.0, 75.0),
        "ideal_ph": (6.0, 7.0),
        "ideal_rainfall": (80.0, 140.0),
        "ideal_soil": "Deep, well-aerated volcanic / Sandy Loam",
        "description": "Nutrient-dense tropical tree fruit intolerant to heavy water stagnation and phytophthora root rot.",
        "farmer_tip": "Plant on elevated mounds. Mulch heavily with woodchips to foster healthy shallow feeder roots."
    },
    "dragonfruit": {
        "display_name": "Dragon Fruit (Pitaya)",
        "category": "Fruit",
        "ideal_temp": (22.0, 38.0),
        "ideal_humidity": (40.0, 65.0),
        "ideal_moisture": (25.0, 50.0),
        "ideal_ph": (5.5, 7.0),
        "ideal_rainfall": (40.0, 90.0),
        "ideal_soil": "Sandy Loam / Gravelly with organic manure",
        "description": "Climbing cactus producing vibrant exotic fruits with extremely low irrigation demands.",
        "farmer_tip": "Train vines on sturdy concrete poles with tire rings. Provide light drip irrigation once a week."
    },
    "fig": {
        "display_name": "Fig (Anjeer)",
        "category": "Fruit",
        "ideal_temp": (18.0, 35.0),
        "ideal_humidity": (35.0, 60.0),
        "ideal_moisture": (25.0, 50.0),
        "ideal_ph": (6.5, 8.2),
        "ideal_rainfall": (35.0, 70.0),
        "ideal_soil": "Gravelly / Calcareous Loam with good drainage",
        "description": "Ancient drought-tolerant fruit tree thriving under warm Mediterranean and semi-arid weather.",
        "farmer_tip": "Prune dormant trees in January. Reduce irrigation during fruit ripening to prevent skin cracking."
    },
    "blueberry": {
        "display_name": "Blueberry",
        "category": "Fruit",
        "ideal_temp": (10.0, 22.0),
        "ideal_humidity": (60.0, 80.0),
        "ideal_moisture": (55.0, 75.0),
        "ideal_ph": (4.5, 5.5),
        "ideal_rainfall": (80.0, 140.0),
        "ideal_soil": "Acidic peat / Sandy Loam rich in organic matter",
        "description": "Temperate high-antioxidant berry that strictly demands acidic soil and cool chilling hours.",
        "farmer_tip": "Incorporate elemental sulphur and sphagnum peat moss to keep soil pH within 4.5 - 5.2."
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
        soil_moisture_percent: Optional[float] = None,
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
                nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm, soil_moisture_percent
            )

        try:
            pred_crop = str(self.model.predict(sample_df)[0]).lower()
            probs = self.model.predict_proba(sample_df)[0]
            classes = self.model.classes_

            # Sort top classes by probability
            top_indices = np.argsort(probs)[::-1]
            top_prob = float(probs[top_indices[0]])

            alternatives: List[Dict[str, Any]] = []
            for idx in top_indices[1:6]:
                crop_name = str(classes[idx]).lower()
                alt_prob = float(probs[idx])
                if alt_prob > 0.03:  # Report realistic alternatives
                    profile = CROP_PROFILES.get(crop_name, {})
                    alternatives.append({
                        "crop": crop_name,
                        "display_name": profile.get("display_name", crop_name.capitalize()),
                        "category": profile.get("category", "Field Crop"),
                        "suitability_percent": round(alt_prob * 100, 1),
                        "farmer_tip": profile.get("farmer_tip", ""),
                    })

            profile = CROP_PROFILES.get(pred_crop, {})
            display_name = profile.get("display_name", pred_crop.capitalize())
            category = profile.get("category", "Field Crop")

            # Evaluate suitability factors
            factors = self._evaluate_factors(
                pred_crop, nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm, soil_moisture_percent
            )

            inputs_dict = {
                "nitrogen": round(float(nitrogen), 1),
                "phosphorus": round(float(phosphorus), 1),
                "potassium": round(float(potassium), 1),
                "temperature_c": round(float(temperature_c), 1),
                "humidity_percent": round(float(humidity_percent), 1),
                "ph": round(float(ph), 2),
                "rainfall_mm": round(float(rainfall_mm), 1),
            }
            if soil_moisture_percent is not None:
                inputs_dict["soil_moisture_percent"] = round(float(soil_moisture_percent), 1)

            return {
                "available": True,
                "recommended_crop": pred_crop,
                "display_name": display_name,
                "category": category,
                "confidence": round(top_prob, 3),
                "suitability_percent": round(top_prob * 100, 1),
                "description": profile.get("description", "Agronomically suited crop for this land."),
                "farmer_tip": profile.get("farmer_tip", "Ensure recommended soil preparation and timely sowing."),
                "ideal_soil": profile.get("ideal_soil", "Loamy / Well-drained"),
                "alternatives": alternatives,
                "factors_analysis": factors,
                "inputs": inputs_dict,
            }
        except Exception as e:
            logger.error("Error during crop inference: %s", e)
            return self._fallback_prediction(
                nitrogen, phosphorus, potassium, temperature_c, humidity_percent, ph, rainfall_mm, soil_moisture_percent
            )

    def _evaluate_factors(
        self,
        crop: str,
        n: float,
        p: float,
        k: float,
        temp: float,
        hum: float,
        ph: float,
        rain: float,
        moisture: Optional[float] = None,
    ) -> List[Dict[str, Any]]:
        """Generates detailed farmer-friendly factor ratings."""
        profile = CROP_PROFILES.get(crop, {})
        factors = []

        # 1. Soil Moisture (Live ESP32 sensor)
        if moisture is not None:
            m_min, m_max = profile.get("ideal_moisture", (40.0, 75.0))
            m_ok = m_min <= moisture <= m_max
            m_status = "OPTIMAL" if m_ok else ("HIGH" if moisture > m_max else "LOW")
            factors.append({
                "parameter": "Soil Moisture",
                "current": f"{moisture:.1f} %",
                "ideal_range": f"{m_min:.0f} - {m_max:.0f} %",
                "status": m_status,
                "is_favorable": m_ok,
                "current_num": round(float(moisture), 1),
                "ideal_min": float(m_min),
                "ideal_max": float(m_max),
                "unit": "%",
            })

        # 2. Temperature (Live DHT11 sensor)
        t_min, t_max = profile.get("ideal_temp", (18.0, 32.0))
        t_ok = t_min <= temp <= t_max
        t_status = "OPTIMAL" if t_ok else ("HIGH" if temp > t_max else "LOW")
        factors.append({
            "parameter": "Temperature",
            "current": f"{temp:.1f} °C",
            "ideal_range": f"{t_min:.0f} - {t_max:.0f} °C",
            "status": t_status,
            "is_favorable": t_ok,
            "current_num": round(float(temp), 1),
            "ideal_min": float(t_min),
            "ideal_max": float(t_max),
            "unit": "°C",
        })

        # 3. Relative Humidity (Live DHT11 sensor)
        h_min, h_max = profile.get("ideal_humidity", (50.0, 80.0))
        h_ok = h_min <= hum <= h_max
        h_status = "OPTIMAL" if h_ok else ("HIGH" if hum > h_max else "LOW")
        factors.append({
            "parameter": "Relative Humidity",
            "current": f"{hum:.1f} %",
            "ideal_range": f"{h_min:.0f} - {h_max:.0f} %",
            "status": h_status,
            "is_favorable": h_ok,
            "current_num": round(float(hum), 1),
            "ideal_min": float(h_min),
            "ideal_max": float(h_max),
            "unit": "%",
        })

        # 4. Soil pH
        ph_min, ph_max = profile.get("ideal_ph", (6.0, 7.5))
        ph_ok = ph_min <= ph <= ph_max
        factors.append({
            "parameter": "Soil pH",
            "current": f"{ph:.2f}",
            "ideal_range": f"{ph_min:.1f} - {ph_max:.1f}",
            "status": "OPTIMAL" if ph_ok else ("ALKALINE" if ph > ph_max else "ACIDIC"),
            "is_favorable": ph_ok,
            "current_num": round(float(ph), 2),
            "ideal_min": float(ph_min),
            "ideal_max": float(ph_max),
            "unit": "",
        })

        # 5. Soil Nutrients
        n_status = "ADEQUATE" if n >= 40 else ("LOW" if n < 25 else "MODERATE")
        factors.append({
            "parameter": "Soil Nitrogen (N)",
            "current": f"{n:.0f} kg/ha",
            "ideal_range": "> 40 kg/ha",
            "status": n_status,
            "is_favorable": n >= 30,
            "current_num": round(float(n), 1),
            "ideal_min": 35.0,
            "ideal_max": 140.0,
            "unit": "kg/ha",
        })

        return factors

    def _fallback_prediction(
        self,
        n: float,
        p: float,
        k: float,
        temp: float,
        hum: float,
        ph: float,
        rain: float,
        moisture: Optional[float] = None,
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
            "category": profile.get("category", "Field Crop"),
            "confidence": 0.85,
            "suitability_percent": 85.0,
            "description": profile.get("description", "Recommended by agronomic rule engine."),
            "farmer_tip": profile.get("farmer_tip", "Ensure balanced basal fertilizer application."),
            "ideal_soil": profile.get("ideal_soil", "Loamy"),
            "alternatives": [],
            "factors_analysis": self._evaluate_factors(pred, n, p, k, temp, hum, ph, rain, moisture),
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
