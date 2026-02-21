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

        result = process_single_frame(img)
        return jsonify(result)

    except Exception as e:
        print(f"Face Analysis Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

def process_single_frame(img):
    """Processes a single frame and returns emotion data."""
    if img is None:
        return {"status": "error", "message": "Empty frame"}

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)

    if len(faces) == 0:
        return {
            "status": "success",
            "dominant_emotion": "neutral",
            "score": 0.0,
            "message": "No face detected"
        }

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
            
            # Get dominant emotion
            idx = np.argmax(probs)
            dominant_emotion = EMOTIONS[idx]
            score = float(probs[idx])
            
            details = {emotion: float(prob) for emotion, prob in zip(EMOTIONS, probs)}
        except Exception as e:
            print(f"Inference Error: {e}")
    
    return {
        "status": "success",
        "dominant_emotion": dominant_emotion,
        "score": score,
        "details": details
    }

import tempfile

@app.route('/analyze_video', methods=['POST'])
def analyze_video():
    """Processes a 5-10s video and returns aggregated visual sentiment."""
    try:
        data = request.get_json()
        video_data = data.get('video', '')

        if not video_data:
            return jsonify({"status": "error", "message": "No video provided"}), 400

        if ',' in video_data:
            video_data = video_data.split(',')[1]

        # Decode and save to temp file
        decoded_video = base64.b64decode(video_data)
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as temp_video:
            temp_video.write(decoded_video)
            video_path = temp_video.name

        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        # We sample every 500ms
        sample_rate = int(fps / 2) if fps > 0 else 1
        if sample_rate == 0: sample_rate = 1

        emotion_history = []
        counts = {emotion: 0 for emotion in EMOTIONS}
        scores = {emotion: 0.0 for emotion in EMOTIONS}

        current_frame = 0
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            if current_frame % sample_rate == 0:
                result = process_single_frame(frame)
                if result['status'] == 'success' and 'details' in result:
                    emotion_history.append(result['dominant_emotion'])
                    for emotion, prob in result['details'].items():
                        counts[emotion] += 1
                        scores[emotion] += prob
            
            current_frame += 1

        cap.release()
        os.unlink(video_path) # Delete temp file

        if not emotion_history:
            return jsonify({
                "status": "success",
                "dominant_emotion": "neutral",
                "message": "No faces detected in video",
                "video_summary": {}
            })

        # Aggregate
        summary = {}
        for emotion in EMOTIONS:
            if counts[emotion] > 0:
                summary[emotion] = scores[emotion] / counts[emotion]
            else:
                summary[emotion] = 0.0

        dominant = max(summary, key=summary.get)

        return jsonify({
            "status": "success",
            "dominant_emotion": dominant,
            "overall_score": summary[dominant],
            "visual_sentiment_profile": summary,
            "frame_count": current_frame,
            "samples": len(emotion_history)
        })

    except Exception as e:
        print(f"Video Analysis Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/combined_report', methods=['POST'])
def combined_report():
    """Combines questionnaire results with visual sentiment for a holistic insight."""
    try:
        data = request.get_json()
        q_results = data.get('questionnaire_results', []) # List of DomainScore objects (serialized)
        v_sentiment = data.get('visual_sentiment', {}) # Output from /analyze_video

        dominant_visual = v_sentiment.get('dominant_emotion', 'neutral')
        visual_profile = v_sentiment.get('visual_sentiment_profile', {})

        # Basic Correlation Logic
        insights = []
        high_risk_domains = [r for r in q_results if r.get('highestScore', 0) >= 3]
        
        # 1. Congruency Check
        if dominant_visual in ['sadness', 'anger', 'fear'] and high_risk_domains:
            insights.append("Visual indicators align with your reported symptoms, confirming the intensity of your current state.")
        elif dominant_visual == 'happiness' and high_risk_domains:
            insights.append("Your visual expression shows resilience/positivity despite reported challenges.")

        # 2. Specific Domain Insights
        for res in q_results:
            domain = res.get('domainName', '')
            score = res.get('highestScore', 0)
            
            if domain == 'Depression' and score >= 3 and visual_profile.get('sadness', 0) > 0.3:
                insights.append("High Depression score correlated with significant visual sadness indicators.")
            if domain == 'Anxiety' and score >= 3 and visual_profile.get('fear', 0) > 0.3:
                insights.append("Reporting high Anxiety with visual signs of tension/fear.")

        if not insights:
            insights.append("Further clinical review is recommended to fully understand the relationship between your self-report and visual indicators.")

        return jsonify({
            "status": "success",
            "holistic_insight": " ".join(insights),
            "visual_summary": {
                "dominant": dominant_visual,
                "confidence": v_sentiment.get('overall_score', 0)
            },
            "risk_level": "High" if high_risk_domains else "Moderate" if q_results else "Low"
        })

    except Exception as e:
        print(f"Combined Report Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    print("Starting MindGauge ML API...")
    print("Test endpoint available at: http://localhost:5000/test")
    app.run(host='0.0.0.0', port=5000)