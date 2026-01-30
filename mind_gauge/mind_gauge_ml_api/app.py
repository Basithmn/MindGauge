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

        # 1. EXACT FILENAME MAPPING (Based on your image)
        name_map = {
            "anger": "anger",
            "anxiety": "anxiety",
            "depression": "depression",
            "mania": "mania",
            "repetitive_thoughts_and_behaviors": "repetitive_thoughts",
            "sleep_problems": "sleep",
            "somatic_symptoms": "somatic",
            "substance_use": "substance_use",
            "level1_diagnosis": "level1_diagnosis"
        }
        
        # Get the prefix (e.g., 'repetitive_thoughts')
        file_prefix = name_map.get(domain, domain)

        model_path = os.path.join(BASE_DIR, f"{group}_model", f"{file_prefix}_lgbm_model.pkl")
        encoder_path = os.path.join(BASE_DIR, f"{group}_model", f"{file_prefix}_label_encoder.pkl")

        if not os.path.exists(model_path):
            print(f"Error: Model not found at {model_path}")
            return jsonify({"error": f"Model for {file_prefix} not found"}), 404

        # 2. LOAD MODEL & ENCODER
        model = joblib.load(model_path)
        encoder = joblib.load(encoder_path)
        
        # 3. FIX BOOSTER ATTRIBUTE ERROR
        # Booster objects use .num_feature() instead of .n_features_
        if hasattr(model, 'num_feature'):
            expected_features = model.num_feature()
        elif hasattr(model, 'n_features_in_'):
            expected_features = model.n_features_in_
        else:
            expected_features = len(responses)

        # 4. AUTO-RESIZE
        if len(responses) > expected_features:
            responses = responses[:expected_features]
        elif len(responses) < expected_features:
            responses = responses + [0] * (expected_features - len(responses))

        # 5. PREDICT
        input_df = pd.DataFrame([responses])
        prediction = model.predict(input_df)
        
        # LightGBM Boosters often return a 2D array of probabilities
        if hasattr(prediction, 'shape') and len(prediction.shape) > 1:
            prediction_idx = prediction.argmax(axis=1)[0]
        else:
            prediction_idx = prediction[0]

        # 6. DECODE
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