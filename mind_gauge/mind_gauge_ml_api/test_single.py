import joblib
import os
try:
    model = joblib.load("adult_model/anxiety_lgbm_model.pkl")
    if hasattr(model, 'n_features_in_'):
        print(f"Anxiety Features: {model.n_features_in_}")
    elif hasattr(model, 'num_feature'):
        print(f"Anxiety Features: {model.num_feature()}")
    else:
        print("Unknown feature count")
except Exception as e:
    print(f"Error: {e}")
