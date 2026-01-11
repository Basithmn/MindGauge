import joblib
import pandas as pd
import numpy as np
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/children_model/anxiety_lgbm_model.pkl'
ENCODER_PATH = '../../models/children_model/anxiety_label_encoder.pkl'

try:
    model = joblib.load(MODEL_PATH) 
    le = joblib.load(ENCODER_PATH) 
except FileNotFoundError:
    print(f"FATAL ERROR: Anxiety model files not found at {MODEL_PATH}.")
    exit()

def sanitize_name(name):
    """Applies the exact same sanitization used during training."""
    name = str(name).strip().replace(' ', '_').replace('(', '').replace(')', '')
    name = name.replace(',', '_').replace('.', '_').replace('-', '_').replace(':', '_')
    name = re.sub(r'__+', '_', name).strip('_')
    return name

def predict_anxiety_severity(raw_scores):
    """
    Accepts 13 raw PROMIS scores and calculates the required 15 features.
    (13 Items + Total Raw Score + Prorated Score)
    """
    if len(raw_scores) != 13:
        raise ValueError("Input must contain exactly 13 scores for the Children's Anxiety scale.")
        
    # Step 1: Calculate Total Raw Score (TR) and Prorated Score (PS)
    tr = sum(raw_scores)
    ps = tr
    
    # Step 2: Assemble the 15-Feature Input List
    input_data = list(raw_scores) + [tr, ps]
    
    symptom_names = [f'Q{i}' for i in range(1, 14)]
    feature_columns = [
        sanitize_name(name) for name in symptom_names
    ] + [
        sanitize_name('Total Raw Score (TR)'), 
        sanitize_name('Prorated Score (PS)')
    ]
    
    df = pd.DataFrame([input_data], columns=feature_columns)
    
    # Step 3: Predict and Decode
    prediction = model.predict(df)
    
    if len(prediction.shape) > 1:
        encoded_val = np.argmax(prediction[0]) 
    else:
        encoded_val = int(prediction[0])
        
    return le.inverse_transform([encoded_val])[0]

if __name__ == '__main__':
    # Test cases using direct scores (PROMIS Children usually 1-5 scale)
    scores_1 = [5, 4, 5, 5, 4, 5, 5, 4, 5, 4, 5, 5, 4] 
    scores_2 = [1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1]
    
    print("-" * 50)
    print("CHILDREN ANXIETY (PROMIS-13) PREDICTOR")
    print("-" * 50)
    print(f"Scores: {scores_1} | Result: {predict_anxiety_severity(scores_1)}")
    print(f"Scores: {scores_2} | Result: {predict_anxiety_severity(scores_2)}")
    print("-" * 50)