from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import os

app = Flask(__name__)
CORS(app) 

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        group = data.get('group')
        domain = data.get('domain').lower()
        responses = data.get('responses')

        # 1. STANDARDIZED MAPPING
        name_map = {
            "level1": "level1_diagnosis",
            "repetitive_thoughts_and_behaviors": "repetitive_thoughts",
            "somatic_symptoms": "somatic",
            "sleep_problems": "sleep",
            "substance_use": "substance_use",
            "suicidal_ideation": "suicidal", # Matches your new script naming
            "personality_functioning": "personality_functioning"
        }
        
        file_prefix = name_map.get(domain, domain)

        model_path = os.path.join(BASE_DIR, f"{group}_model", f"{file_prefix}_lgbm_model.pkl")
        encoder_path = os.path.join(BASE_DIR, f"{group}_model", f"{file_prefix}_label_encoder.pkl")

        if not os.path.exists(model_path):
            # Fallback for missing models to prevent Flutter crashes
            return jsonify({
                "status": "success",
                "prediction": "Clinical Review Required",
                "domain": domain
            })

        model = joblib.load(model_path)
        encoder = joblib.load(encoder_path)
        
        # 2. FEATURE VALIDATION
        # For Level 1, we expect 13 domain scores
        if file_prefix == "level1_diagnosis":
            expected_features = 13
        elif hasattr(model, 'num_feature'):
            expected_features = model.num_feature()
        elif hasattr(model, 'n_features_in_'):
            expected_features = model.n_features_in_
        else:
            expected_features = len(responses)

        # 3. AUTO-RESIZE / PADDING
        if len(responses) > expected_features:
            responses = responses[:expected_features]
        elif len(responses) < expected_features:
            responses = responses + [0] * (expected_features - len(responses))

        # 4. INFERENCE
        input_df = pd.DataFrame([responses])
        prediction = model.predict(input_df)
        
        # Handle multiclass array output
        if hasattr(prediction, 'shape') and len(prediction.shape) > 1:
            prediction_idx = prediction.argmax(axis=1)[0]
        else:
            prediction_idx = prediction[0]

        label = encoder.inverse_transform([int(prediction_idx)])[0]

        print(f"Success: {group}/{file_prefix} -> {label}")
        return jsonify({
            "status": "success",
            "prediction": str(label),
            "domain": domain
        })

    except Exception as e:
        print(f"Server Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)