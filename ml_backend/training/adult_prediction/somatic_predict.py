import joblib
import pandas as pd
import numpy as np
import math
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/adult_model/somatic_lgbm_model.pkl'
ENCODER_PATH = '../../models/adult_model/somatic_label_encoder.pkl'

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

def predict_somatic_severity(raw_symptom_scores):
    """
    Accepts 15 raw PHQ-15 scores and calculates the required 17 features.
    """
    if len(raw_symptom_scores) != 15:
        raise ValueError("Input must contain exactly 15 scores for the PHQ-15 scale.")
        
    processed_scores = list(raw_symptom_scores)
            
    # --- Step 1: Calculate Total Raw Score (TR) and Prorated Score (PS) ---
    total_raw_score = sum(processed_scores)
    prorated_score = total_raw_score
    
    # --- Step 2: Assemble the 17-Feature Input List and Names ---
    input_list_17 = processed_scores + [total_raw_score, prorated_score]
    
    symptom_names = [f'Q{i}' for i in range(1, 16)]
    
    feature_columns = [
        sanitize_name(name) for name in symptom_names
    ] + [
        sanitize_name('Total Raw Score (TR)'), 
        sanitize_name('Prorated Score (PS)')
    ]
    
    new_data = pd.DataFrame([input_list_17], columns=feature_columns)
    
    # --- Step 3: Predict and Decode ---
    raw_prediction = model.predict(new_data)
    
    if len(raw_prediction.shape) > 1:
        encoded_prediction = np.argmax(raw_prediction[0]) 
    else:
        encoded_prediction = int(raw_prediction[0])
        
    predicted_label = le.inverse_transform([encoded_prediction])[0]
    
    return predicted_label

if __name__ == '__main__':
    # Example Test Cases
    test_1 = [2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1, 2] 
    test_2 = [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0]
    
    print(f"Scores: {test_1} | Prediction: {predict_somatic_severity(test_1)}")
    print(f"Scores: {test_2} | Prediction: {predict_somatic_severity(test_2)}")