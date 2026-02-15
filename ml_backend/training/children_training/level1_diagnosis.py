import sys
import os
import joblib
import pandas as pd
import lightgbm as lgb
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score

if __name__ == '__main__':
    # 1. Paths
    FILE_PATH = "../../data/children_scores/level1_children_scores.csv"
    MODEL_OUTPUT_PATH = "../../models/children_model/level1_diagnosis_lgbm_model.pkl"
    LABEL_ENCODER_PATH = "../../models/children_model/level1_diagnosis_label_encoder.pkl"
    
    # 12 Core Clinical Domains for Children
    FEATURE_COLUMNS = [
        'Somatic_Score', 'Sleep_Disturbance_Score', 'Inattention_Score', 
        'Depression_Score', 'Anger_Score', 'Irritability_Score', 
        'Mania_Score', 'Anxiety_Score', 'Psychosis_Score', 
        'Repetitive_Thoughts_Score', 'Substance_Use_Score', 'Suicidal_Ideation_Score'
    ]
    TARGET_COLUMN = "Clinical_Diagnosis"
    
    os.makedirs(os.path.dirname(MODEL_OUTPUT_PATH), exist_ok=True) 

    try:
        data = pd.read_csv(FILE_PATH)
        X = data[FEATURE_COLUMNS]
        y = data[TARGET_COLUMN]

        le = LabelEncoder()
        y_encoded = le.fit_transform(y)
        
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
        )

        lgb_clf = lgb.LGBMClassifier(
            objective='multiclass',
            num_class=len(le.classes_),
            metric='multi_logloss',
            n_estimators=500,
            learning_rate=0.05,
            random_state=42,
            verbose=-1
        )

        print("🧠 Training Children's Level 1 Model...")
        lgb_clf.fit(X_train, y_train, eval_set=[(X_test, y_test)])

        joblib.dump(lgb_clf, MODEL_OUTPUT_PATH)
        joblib.dump(le, LABEL_ENCODER_PATH)

        accuracy = accuracy_score(y_test, lgb_clf.predict(X_test))
        print(f"✅ Success! Model Accuracy: {accuracy*100:.2f}%")

    except Exception as e:
        print(f"❌ Training failed: {e}")