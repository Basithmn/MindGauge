import joblib
import pandas as pd
import numpy as np
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/children_model/somatic_lgbm_model.pkl'
ENCODER_PATH = '../../models/children_model/somatic_label_encoder.pkl'

try:
    model = joblib.load(MODEL_PATH) 
    le = joblib.load(ENCODER_PATH) 
except FileNotFoundError:
    print(f"FATAL ERROR: Somatic model files not found at {MODEL_PATH}.")
    exit()

def sanitize_name(name):
    """Applies the exact same sanitization used during training."""
    name = str(name).strip().replace(' ', '_').replace('(', '').replace(')', '')
    name = name.replace(',', '_').replace('.', '_').replace('-', '_').replace(':', '_')
    name = re.sub(r'__+', '_', name).strip('_')
    return name

def predict_somatic_severity(raw_scores):
    """
    Accepts 15 raw PHQ-15 scores.
    Matches training data (Exactly 15 features).
    """
    if len(raw_scores) != 15:
        raise ValueError("Input must contain exactly 15 scores for the PHQ-15 Somatic scale.")
    
    # Step 1: Assemble the 15-Feature Input List (Items Only)
    input_data = list(raw_scores)
    
    # Step 2: Create Column Names (Q1 to Q15)
    symptom_names = [f'Q{i}' for i in range(1, 16)]
    feature_columns = [sanitize_name(name) for name in symptom_names]
    
    df = pd.DataFrame([input_data], columns=feature_columns)
    
    # Step 3: Predict and Decode
    prediction = model.predict(df)
    
    if len(prediction.shape) > 1:
        encoded_val = np.argmax(prediction[0]) 
    else:
        encoded_val = int(prediction[0])
        
    return le.inverse_transform([encoded_val])[0]

if __name__ == '__main__':
    # Test cases
    scores_1 = [3, 2, 3, 3, 2, 3, 1, 2, 3, 3, 2, 3, 1, 2, 3]
    scores_2 = [1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1]
    
    print("-" * 40)
    print(f"Scores: {scores_1} | Result: {predict_somatic_severity(scores_1)}")
    print(f"Scores: {scores_2} | Result: {predict_somatic_severity(scores_2)}")
    print("-" * 40)