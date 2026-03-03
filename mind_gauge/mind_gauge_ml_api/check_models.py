import joblib
import os

MODEL_DIR = "adult_model"
for file in os.listdir(MODEL_DIR):
    if file.endswith("_model.pkl"):
        path = os.path.join(MODEL_DIR, file)
        try:
            model = joblib.load(path)
            if hasattr(model, 'n_features_in_'):
                features = model.n_features_in_
            elif hasattr(model, 'num_feature'):
                features = model.num_feature()
            else:
                features = "Unknown"
            print(f"Model: {file} | Features: {features}")
        except Exception as e:
            print(f"Error loading {file}: {e}")
