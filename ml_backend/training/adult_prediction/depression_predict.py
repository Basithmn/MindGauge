import joblib
import pandas as pd
import numpy as np
import re
import os

# --- 1. Model Loading ---
MODEL_PATH = '../../models/adult_model/depression_lgbm_model.pkl'
ENCODER_PATH = '../../models/adult_model/depression_label_encoder.pkl'

try:
    model = joblib.load(MODEL_PATH) 
    le = joblib.load(ENCODER_PATH) 
except FileNotFoundError:
    print(f"FATAL ERROR: Model files not found. Ensure training is complete.")
    exit()

def sanitize_name(name):
    name = str(name).strip().replace(' ', '_').replace('(', '').replace(')', '')
    name = name.replace(',', '_').replace('.', '_').replace('-', '_').replace(':', '_')
    name = re.sub(r'__+', '_', name).strip('_')
    return name

def predict_depression_severity(raw_scores):
    if len(raw_scores) != 8:
        raise ValueError("Input must contain exactly 8 scores.")
        
    # Calculate Total Raw Score (TR) and Prorated Score (PS)
    tr = sum(raw_scores)
    ps = tr  # Assuming full completion
    
    # Assemble 10 features: 8 items + TR + PS
    input_data = list(raw_scores) + [tr, ps]
    
    feature_names = [sanitize_name(f'Q{i}') for i in range(1, 9)] + \
                    [sanitize_name('Total Raw Score (TR)'), sanitize_name('Prorated Score (PS)')]
    
    df = pd.DataFrame([input_data], columns=feature_names)
    
    # Predict
    prediction = model.predict(df)
    encoded_val = np.argmax(prediction[0]) if len(prediction.shape) > 1 else int(prediction[0])
    return le.inverse_transform([encoded_val])[0]

if __name__ == '__main__':
    # Test cases using direct scores
    scores_1 = [5, 4, 5, 5, 4, 5, 5, 4] 
    scores_2 = [1, 1, 2, 1, 1, 1, 1, 1]
    
    print("-" * 30)
    print(f"Scores: {scores_1} | Result: {predict_depression_severity(scores_1)}")
    print(f"Scores: {scores_2} | Result: {predict_depression_severity(scores_2)}")
    print("-" * 30)