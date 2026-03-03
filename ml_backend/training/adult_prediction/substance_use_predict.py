import joblib
import pandas as pd
import numpy as np
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/adult_model/substance_use_lgbm_model.pkl'
ENCODER_PATH = '../../models/adult_model/substance_use_label_encoder.pkl'

try:
    model = joblib.load(MODEL_PATH) 
    le = joblib.load(ENCODER_PATH) 
except FileNotFoundError:
    print(f"FATAL ERROR: Substance Use model files not found.")
    exit()

def sanitize_name(name):
    """Applies the exact same sanitization used during training."""
    name = str(name).strip().replace(' ', '_').replace('(', '').replace(')', '')
    name = name.replace(',', '_').replace('.', '_').replace('-', '_').replace(':', '_')
    name = re.sub(r'__+', '_', name).strip('_')
    return name

def predict_substance_use_category(raw_scores):
    """
    Accepts 10 raw scores and calculates 1 feature (TR).
    Total features: 10 items + 1 TR = 11 features.
    """
    if len(raw_scores) != 10:
        raise ValueError("Input must contain exactly 10 scores.")
        
    # Step 1: Calculate Total Raw Score (TR) only
    tr = sum(raw_scores)
    
    # Step 2: Assemble the 11-Feature Input List (10 Items + TR)
    # We remove the prorated score to match the model's 11-feature training
    input_data = list(raw_scores) + [tr]
    
    symptom_names = [f'Q{i}' for i in range(1, 11)]
    feature_columns = [
        sanitize_name(name) for name in symptom_names
    ] + [
        sanitize_name('Total Raw Score (TR)')
    ]
    
    df = pd.DataFrame([input_data], columns=feature_columns)
    
    # Step 3: Predict and Decode
    prediction = model.predict(df)
    
    if len(prediction.shape) > 1:
        encoded_val = np.argmax(prediction[1]) 
    else:
        encoded_val = int(prediction[0])
        
    return le.inverse_transform([encoded_val])[0]

if __name__ == '__main__':
    # Test cases
    scores_1 = [4, 1, 5, 1, 1, 1, 3, 1, 1, 1]
    scores_2 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    
    print("-" * 40)
    print(f"Scores: {scores_1} | Result: {predict_substance_use_category(scores_1)}")
    print(f"Scores: {scores_2} | Result: {predict_substance_use_category(scores_2)}")
    print("-" * 40)