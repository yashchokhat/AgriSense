import os
import numpy as np
import pandas as pd

CSV_PATH = os.path.join(os.path.dirname(__file__), "data", "crop_recommendation.csv")

new_crops = {
    'wheat':       {'N': (75, 5), 'P': (45, 4), 'K': (45, 4), 'temperature': (18.5, 1.5), 'humidity': (60.0, 3.0), 'ph': (6.5, 0.25), 'rainfall': (75.0, 6.0)},
    'barley':      {'N': (50, 4), 'P': (32, 3), 'K': (32, 3), 'temperature': (16.0, 1.5), 'humidity': (45.0, 3.0), 'ph': (7.3, 0.25), 'rainfall': (50.0, 5.0)},
    'soybean':     {'N': (30, 4), 'P': (75, 5), 'K': (60, 4), 'temperature': (26.0, 1.8), 'humidity': (72.0, 3.0), 'ph': (6.5, 0.2),  'rainfall': (92.0, 8.0)},
    'groundnut':   {'N': (25, 3), 'P': (55, 4), 'K': (40, 3), 'temperature': (29.0, 1.8), 'humidity': (58.0, 3.0), 'ph': (6.6, 0.25), 'rainfall': (65.0, 6.0)},
    'mustard':     {'N': (65, 5), 'P': (38, 3), 'K': (25, 3), 'temperature': (17.0, 1.5), 'humidity': (52.0, 3.0), 'ph': (6.8, 0.25), 'rainfall': (45.0, 5.0)},
    'sunflower':   {'N': (52, 4), 'P': (45, 4), 'K': (52, 4), 'temperature': (25.0, 2.0), 'humidity': (50.0, 3.0), 'ph': (6.7, 0.25), 'rainfall': (60.0, 6.0)},
    'sugarcane':   {'N': (125, 7), 'P': (65, 5), 'K': (75, 5), 'temperature': (31.0, 2.0), 'humidity': (78.0, 3.0), 'ph': (6.8, 0.3),  'rainfall': (220.0, 15.0)},
    'tea':         {'N': (95, 6), 'P': (30, 3), 'K': (50, 4), 'temperature': (20.0, 1.5), 'humidity': (85.0, 3.0), 'ph': (4.8, 0.2),  'rainfall': (215.0, 15.0)},
    'potato':      {'N': (90, 6), 'P': (70, 5), 'K': (110, 6), 'temperature': (18.0, 1.5), 'humidity': (72.0, 3.0), 'ph': (5.6, 0.25), 'rainfall': (85.0, 7.0)},
    'tomato':      {'N': (75, 5), 'P': (65, 5), 'K': (80, 5), 'temperature': (24.0, 1.8), 'humidity': (60.0, 3.0), 'ph': (6.5, 0.2),  'rainfall': (70.0, 6.0)},
    'onion':       {'N': (70, 5), 'P': (50, 4), 'K': (55, 4), 'temperature': (21.0, 1.5), 'humidity': (52.0, 3.0), 'ph': (6.6, 0.2),  'rainfall': (55.0, 5.0)},
    'garlic':      {'N': (60, 4), 'P': (45, 4), 'K': (45, 4), 'temperature': (17.0, 1.5), 'humidity': (50.0, 3.0), 'ph': (6.7, 0.2),  'rainfall': (48.0, 5.0)},
    'strawberry':  {'N': (50, 4), 'P': (55, 4), 'K': (75, 5), 'temperature': (16.0, 1.5), 'humidity': (68.0, 3.0), 'ph': (6.1, 0.2),  'rainfall': (85.0, 7.0)},
    'pineapple':   {'N': (60, 5), 'P': (32, 3), 'K': (105, 6), 'temperature': (28.0, 1.8), 'humidity': (80.0, 3.0), 'ph': (5.0, 0.25), 'rainfall': (140.0, 10.0)},
    'guava':       {'N': (55, 4), 'P': (40, 3), 'K': (50, 4), 'temperature': (28.0, 2.0), 'humidity': (55.0, 3.0), 'ph': (6.5, 0.3),  'rainfall': (75.0, 8.0)},
    'lemon':       {'N': (65, 5), 'P': (38, 3), 'K': (50, 4), 'temperature': (25.0, 2.0), 'humidity': (55.0, 3.0), 'ph': (6.6, 0.3),  'rainfall': (72.0, 7.0)},
    'avocado':     {'N': (65, 5), 'P': (50, 4), 'K': (75, 5), 'temperature': (22.0, 1.8), 'humidity': (65.0, 3.0), 'ph': (6.5, 0.25), 'rainfall': (120.0, 10.0)},
    'dragonfruit': {'N': (40, 4), 'P': (38, 3), 'K': (50, 4), 'temperature': (32.0, 2.0), 'humidity': (45.0, 3.0), 'ph': (6.2, 0.25), 'rainfall': (50.0, 6.0)},
    'fig':         {'N': (45, 4), 'P': (32, 3), 'K': (45, 4), 'temperature': (27.0, 2.0), 'humidity': (42.0, 3.0), 'ph': (7.4, 0.25), 'rainfall': (45.0, 5.0)},
    'blueberry':   {'N': (35, 3), 'P': (35, 3), 'K': (40, 3), 'temperature': (15.0, 1.5), 'humidity': (72.0, 3.0), 'ph': (4.6, 0.2),  'rainfall': (115.0, 8.0)},
}

def expand_dataset():
    df_base = pd.read_csv(CSV_PATH)
    existing_crops = set(df_base['label'].unique())
    
    np.random.seed(42)
    new_rows = []
    for crop, params in new_crops.items():
        if crop in existing_crops:
            continue
        for _ in range(100):
            row = {
                'N': max(0.0, round(float(np.random.normal(params['N'][0], params['N'][1])), 1)),
                'P': max(0.0, round(float(np.random.normal(params['P'][0], params['P'][1])), 1)),
                'K': max(0.0, round(float(np.random.normal(params['K'][0], params['K'][1])), 1)),
                'temperature': round(float(np.random.normal(params['temperature'][0], params['temperature'][1])), 2),
                'humidity': max(10.0, min(100.0, round(float(np.random.normal(params['humidity'][0], params['humidity'][1])), 2))),
                'ph': max(3.5, min(9.5, round(float(np.random.normal(params['ph'][0], params['ph'][1])), 2))),
                'rainfall': max(10.0, round(float(np.random.normal(params['rainfall'][0], params['rainfall'][1])), 2)),
                'label': crop
            }
            new_rows.append(row)

    if new_rows:
        df_combined = pd.concat([df_base, pd.DataFrame(new_rows)], ignore_index=True)
        df_combined.to_csv(CSV_PATH, index=False)
        print(f"Dataset updated! Total rows: {len(df_combined)}, Total crops: {len(df_combined['label'].unique())}")
    else:
        print(f"Dataset already up to date with {len(existing_crops)} crops.")

if __name__ == "__main__":
    expand_dataset()
