import joblib
import pandas as pd
import numpy as np
import os

FEATURE_COLUMNS = [
    'Somatic_Score', 'Sleep_Disturbance_Score', 'Inattention_Score', 
    'Depression_Score', 'Anger_Score', 'Irritability_Score', 
    'Mania_Score', 'Anxiety_Score', 'Psychosis_Score', 
    'Repetitive_Thoughts_Score', 'Substance_Use_Score', 'Suicidal_Ideation_Score'
]

def preprocess_25_to_12(q):
    """Maps 25 raw answers to 12 DSM-5 Child Domains."""
    if len(q) != 25: raise ValueError("25 scores required.")
    return [
        max(q[0], q[1]),                # Somatic (Q1, 2)
        q[2],                           # Sleep (Q3)
        q[3],                           # Inattention (Q4)
        max(q[4], q[5]),                # Depression (Q5, 6)
        q[7],                           # Anger (Q8)
        q[6],                           # Irritability (Q7)
        max(q[8], q[9]),                # Mania (Q9, 10)
        max(q[10], q[11], q[12]),       # Anxiety (Q11, 12, 13)
        max(q[13], q[14]),              # Psychosis (Q14, 15)
        max(q[15], q[16], q[17], q[18]),# Repetitive (Q16-19)
        max(q[19], q[20], q[21], q[22]),# Substance (Q20-23)
        max(q[23], q[24])               # Suicidal (Q24, 25)
    ]

def get_clinical_report(raw_25_scores):
    MODEL_PATH = '../../models/children_model/level1_diagnosis_lgbm_model.pkl'
    ENCODER_PATH = '../../models/children_model/level1_diagnosis_label_encoder.pkl'
    
    if not os.path.exists(MODEL_PATH):
        return "Error: Model not trained."

    model = joblib.load(MODEL_PATH)
    le = joblib.load(ENCODER_PATH)
    
    # 1. Process Mapping
    domain_scores = preprocess_25_to_12(raw_25_scores)
    
    # 2. Predict Diagnosis
    X_input = pd.DataFrame([domain_scores], columns=FEATURE_COLUMNS)
    diagnosis = le.inverse_transform([model.predict(X_input)[0]])[0]
    
    # 3. Referral Thresholds (1 for risk domains, 2 for others)
    THRESHOLDS = [2, 2, 1, 2, 2, 2, 2, 2, 1, 2, 1, 1]
    referrals = {}
    
    for i, name in enumerate(FEATURE_COLUMNS):
        if domain_scores[i] >= THRESHOLDS[i]:
            clean_name = name.replace('_Score', '').upper()
            referrals[clean_name] = f"Score: {domain_scores[i]} (Threshold: {THRESHOLDS[i]})"
            
    return {"diagnosis": diagnosis, "referrals": referrals}

if __name__ == '__main__':
    # Test: All 1s (Slight)
    test_answers = [1] * 25
    report = get_clinical_report(test_answers)
    print(f"\nDIAGNOSIS: {report['diagnosis']}")
    print("ACTION ITEMS:", report['referrals'])