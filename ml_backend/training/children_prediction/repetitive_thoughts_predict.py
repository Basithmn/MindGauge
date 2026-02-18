import joblib
import pandas as pd
import numpy as np
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/children_model/repetitive_thoughts_lgbm_model.pkl'
ENCODER_PATH = '../../models/children_model/repetitive_thoughts_label_encoder.pkl'

try:
    model = joblib.load(MODEL_PATH) 
    le = joblib.load(ENCODER_PATH) 
except FileNotFoundError:
    print(f"FATAL ERROR: Repetitive Thoughts model files not found at {MODEL_PATH}.")
    exit()

def sanitize_name(name):
    """Applies the exact same sanitization used during training."""
    name = str(name).strip().replace(' ', '_').replace('(', '').replace(')', '')
    name = name.replace(',', '_').replace('.', '_').replace('-', '_').replace(':', '_')
    name = re.sub(r'__+', '_', name).strip('_')
    return name

def predict_repetitive_thoughts_severity(raw_scores):
    """
    Accepts 5 raw C-FOCI scores and calculates the required 7 features.
    (5 Items + Total Raw Score + Prorated Score)
    """
    if len(raw_scores) != 5:
        raise ValueError("Input must contain exactly 5 scores for the Repetitive Thoughts scale.")
        
    # Step 1: Calculate Total Raw Score (TR) and Prorated Score (PS)
    tr = sum(raw_scores)
    ps = tr
    
    # Step 2: Assemble the 7-Feature Input List
    input_data = list(raw_scores) + [tr, ps]
    
    symptom_names = [f'Q{i}' for i in range(1, 6)]
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
    # Test cases using direct scores (C-FOCI range is typically 0-4)
    scores_1 = [5, 5, 4, 5, 4] 
    scores_2 = [1, 2, 1, 1, 1]
    
    print("-" * 50)
    print("CHILDREN REPETITIVE THOUGHTS (C-FOCI) PREDICTOR")
    print("-" * 50)
    print(f"Scores: {scores_1} | Result: {predict_repetitive_thoughts_severity(scores_1)}")
    print(f"Scores: {scores_2} | Result: {predict_repetitive_thoughts_severity(scores_2)}")
    print("-" * 50)