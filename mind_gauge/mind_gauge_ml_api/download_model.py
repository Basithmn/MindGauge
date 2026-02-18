import urllib.request
import os

# Updated URL from search results
model_url = "https://github.com/onnx/models/raw/main/validated/vision/body_analysis/emotion_ferplus/model/emotion-ferplus-8.onnx"
model_path = "emotion-ferplus-8.onnx"

if not os.path.exists(model_path):
    print(f"Downloading model from {model_url}...")
    try:
        # User-Agent header might be needed for some servers
        opener = urllib.request.build_opener()
        opener.addheaders = [('User-agent', 'Mozilla/5.0')]
        urllib.request.install_opener(opener)
        
        urllib.request.urlretrieve(model_url, model_path)
        print("Download complete.")
        print(f"File size: {os.path.getsize(model_path)} bytes")
    except Exception as e:
        print(f"Failed to download model: {e}")
else:
    print("Model already exists.")
