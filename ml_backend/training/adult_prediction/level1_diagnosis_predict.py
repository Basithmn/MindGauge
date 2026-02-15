import joblib
import pandas as pd
import numpy as np
import os

# --- 1. GLOBAL CONFIGURATION ---
# These names MUST match the columns in your training CSV exactly.
FEATURE_COLUMNS = [
    'Depression_Score', 
    'Anger_Score', 
    'Mania_Score', 
    'Anxiety_Score', 
    'Somatic_Score', 
    'Sleep_Disturbance_Score', 
    'Repetitive_Thoughts_Score',
    'Substance_Use_Score', 
    'Suicidal_Score', 
    'Psychosis_Score', 
    'Memory_Score', 
    'Dissociation_Score', 
    'Personality_Functioning_Score'
]

# Path to the saved model artifacts
MODEL_PATH = '../../models/adult_model/level1_diagnosis_lgbm_model.pkl'
ENCODER_PATH = '../../models/adult_model/level1_diagnosis_label_encoder.pkl'

def preprocess_23_to_13(q):
    """
    Official DSM-5 Mapping: 23 individual question scores -> 13 Clinical Domains.
    Uses the 'Highest Item Score' logic (max value in each section).
    """
    if len(q) != 23:
        raise ValueError(f"Expected 23 question scores, but received {len(q)}.")

    return [
        max(q[0], q[1]),               # I. Depression (Q1, Q2)
        q[2],                          # II. Anger (Q3)
        max(q[3], q[4]),               # III. Mania (Q4, Q5)
        max(q[5], q[6], q[7]),         # IV. Anxiety (Q6, Q7, Q8)
        max(q[8], q[9]),               # V. Somatic (Q9, Q10)
        q[13],                         # VIII. Sleep Disturbance (Q14)
        max(q[15], q[16]),             # X. Repetitive Thoughts (Q16, Q17)
        max(q[20], q[21], q[22]),      # XIII. Substance Use (Q21, Q22, Q23)
        q[10],                         # VI. Suicidal Ideation (Q11)
        max(q[11], q[12]),             # VII. Psychosis (Q12, Q13)
        q[14],                         # IX. Memory (Q15)
        q[17],                         # XI. Dissociation (Q18)
        max(q[18], q[19])              # XII. Personality Functioning (Q19, Q20)
    ]

def get_clinical_report(raw_23_scores):
    """
    Processes raw inputs, predicts diagnosis, and checks for referral thresholds.
    """
    # Verify model files exist
    if not os.path.exists(MODEL_PATH) or not os.path.exists(ENCODER_PATH):
        return {"error": "Model artifacts not found. Please run the training script first."}

    # Load Model and Encoder
    model = joblib.load(MODEL_PATH)
    le = joblib.load(ENCODER_PATH)
    
    # 1. Map 23 Raw Answers -> 13 Clinical Features
    domain_scores = preprocess_23_to_13(raw_23_scores)
    
    # 2. Predict Diagnosis (Wrapped in DataFrame to include feature names)
    X_input = pd.DataFrame([domain_scores], columns=FEATURE_COLUMNS)
    diag_idx = model.predict(X_input)[0]
    diagnosis = le.inverse_transform([diag_idx])[0]
    
    # 3. Level 2 Referral Logic (DSM-5 Thresholds)
    # Threshold 1 (Slight) for high-risk domains, 2 (Mild) for others.
    THRESHOLDS = [2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2]
    
    referrals = {}
    for i, name in enumerate(FEATURE_COLUMNS):
        if domain_scores[i] >= THRESHOLDS[i]:
            # Cleanup name for display (e.g., 'Depression_Score' -> 'DEPRESSION')
            display_name = name.replace('_Score', '').upper()
            referrals[display_name] = f"Score: {domain_scores[i]} (Level 1 Threshold: {THRESHOLDS[i]})"
            
    return {
        "diagnosis": diagnosis,
        "flagged_referrals": referrals
    }

# --- TEST SCENARIO ---
if __name__ == "__main__":
    # Example: User bothered 'Slightly' (1) by every single problem.
    # This usually results in 'No Diagnosis' but flags high-risk areas.
    sample_answers = [1] * 23 
    
    report = get_clinical_report(sample_answers)
    
    if "error" in report:
        print(report["error"])
    else:
        print("\n" + "="*50)
        print(f"DIAGNOSIS: {report['diagnosis']}")
        print("="*50)
        print("\nACTION ITEMS (Level 2 Deep-Dive Required):")
        
        if report["flagged_referrals"]:
            for domain, detail in report["flagged_referrals"].items():
                print(f" ✅ {domain}: {detail}")
        else:
            print(" None. All scores are below the clinical threshold.")
        print("-" * 50)