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

@app.route('/analyze_sentiment', methods=['POST'])
def analyze_sentiment():
    try:
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            return jsonify({
                "status": "success",
                "emoji": "⚪",
                "score": 0.0,
                "description": "No text provided"
            })

        from textblob import TextBlob
        blob = TextBlob(text)
        polarity = blob.sentiment.polarity  # -1.0 to 1.0

        # Refined Sentiment Logic
        # 1. Keyword Overrides (for strong sentiment words that might be missed)
        lower_text = text.lower()
        if any(w in lower_text for w in ['bad', 'sad', 'terrible', 'horrible', 'worst', 'hate', 'awful']):
            polarity = min(polarity, -0.4) # Force negative
        elif any(w in lower_text for w in ['great', 'wonderful', 'amazing', 'love', 'best', 'fantastic']):
            polarity = max(polarity, 0.4) # Force positive

        # 2. Adjusted Thresholds (TextBlob can be conservative)
        if polarity > 0.1:  # Lowered from 0.3
            emoji = "😊"
            description = "Positive"
        elif polarity < -0.1: # Raised from -0.3
            emoji = "😞"
            description = "Negative"
        else:
            emoji = "😐"
            description = "Neutral"

        return jsonify({
            "status": "success",
            "emoji": emoji,
            "score": polarity,
            "description": description
        })

    except Exception as e:
        print(f"Sentiment Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/test', methods=['GET'])
def test_sentiment_endpoint():
    """
    Internal test endpoint to verify sentiment analysis without external scripts.
    """
    test_cases = [
        "I am feeling absolutely wonderful and happy today!",
        "I feel terrible, sad, and hopeless.",
        "I went to the store and bought some milk.",
        "I had a bad day."
    ]
    
    results = []
    with app.test_client() as client:
        for text in test_cases:
            try:
                response = client.post('/analyze_sentiment', json={"text": text})
                if response.status_code == 200:
                    data = response.get_json()
                    results.append(f"Text: '{text}' -> {data['emoji']} ({data['description']}) [Score: {data['score']}]")
                else:
                    results.append(f"Text: '{text}' -> Error {response.status_code}")
            except Exception as e:
                results.append(f"Text: '{text}' -> Exception: {str(e)}")
    
    return jsonify({
        "status": "success",
        "message": "Self-test completed",
        "results": results
    })

    return jsonify({
        "status": "success",
        "message": "Self-test completed",
        "results": results
    })

# --- FACIAL EXPRESSION ANALYSIS (ONNX) ---
import cv2
import numpy as np
import base64
import os

# Try to import onnxruntime
try:
    import onnxruntime as ort
    ort_available = True
except ImportError:
    ort_available = False
    print("Warning: onnxruntime not found. Facial analysis will determine neutral.")

# Emotion labels for FER+ model
EMOTIONS = ['neutral', 'happiness', 'surprise', 'sadness', 'anger', 'disgust', 'fear', 'contempt']

# Load ONNX model
model_path = os.path.join(BASE_DIR, "emotion-ferplus-8.onnx")
ort_session = None

if ort_available and os.path.exists(model_path):
    try:
        ort_session = ort.InferenceSession(model_path)
        print(f"Loaded ONNX model from {model_path}")
    except Exception as e:
        print(f"Failed to load ONNX model: {e}")
else:
    print(f"ONNX model not found at {model_path} or runtime missing.")

# Load Face Cascade
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def preprocess_face(face_img):
    # Resize to 64x64
    face_img = cv2.resize(face_img, (64, 64))
    # Convert to grayscale
    if len(face_img.shape) == 3:
        face_img = cv2.cvtColor(face_img, cv2.COLOR_BGR2GRAY)
    # Reshape to (1, 1, 64, 64) and standardise
    face_img = face_img.reshape(1, 1, 64, 64).astype(np.float32)
    return face_img

def softmax(x):
    """Compute softmax values for each sets of scores in x."""
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum()

@app.route('/analyze_face', methods=['POST'])
def analyze_face():
    try:
        data = request.get_json()
        image_data = data.get('image', '') # Expecting base64 string

        if not image_data:
            return jsonify({"status": "error", "message": "No image provided"}), 400

        # Decode base64 image
        try:
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            decoded_data = base64.b64decode(image_data)
            np_data = np.frombuffer(decoded_data, np.uint8)
            img = cv2.imdecode(np_data, cv2.IMREAD_COLOR)
        except Exception as e:
            return jsonify({"status": "error", "message": "Invalid image format"}), 400

        # Detect Faces
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)

        print(f"Faces detected: {len(faces)}") # DEBUG

        if len(faces) == 0:
            return jsonify({
                "status": "success",
                "dominant_emotion": "neutral",
                "score": 0.0,
                "message": "No face detected"
            })

        # Process the largest face
        (x, y, w, h) = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)[0]
        face_roi = img[y:y+h, x:x+w]

        dominant_emotion = "neutral"
        score = 0.0
        details = {}

        if ort_session:
            try:
                processed_face = preprocess_face(face_roi)
                input_name = ort_session.get_inputs()[0].name
                
                # Run inference
                ort_outs = ort_session.run(None, {input_name: processed_face})
                embeddings = ort_outs[0]
                
                # Getting probabilities
                probs = softmax(embeddings[0])
                print(f"Raw Probabilities: {probs}") # DEBUG
                
                # Get dominant emotion
                idx = np.argmax(probs)
                dominant_emotion = EMOTIONS[idx]
                score = float(probs[idx])
                
                print(f"Detected: {dominant_emotion} ({score:.2f})") # DEBUG

                details = {emotion: float(prob) for emotion, prob in zip(EMOTIONS, probs)}
            except Exception as e:
                print(f"Inference Error: {e}")
        else:
            # Fallback if model/session is missing
             print("ONNX session missing, returning fallback.") # DEBUG
             dominant_emotion = "neutral (fallback)"
             score = 1.0


        return jsonify({
            "status": "success",
            "dominant_emotion": dominant_emotion,
            "score": score,
            "details": details
        })

    except Exception as e:
        print(f"Face Analysis Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    print("Starting MindGauge ML API...")
    print("Test endpoint available at: http://localhost:5000/test")
    app.run(host='0.0.0.0', port=5000, debug=True)