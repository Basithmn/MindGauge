import cv2
import requests
import base64
import json

# Configuration
API_URL = "http://localhost:5000/analyze_face"

def capture_and_analyze():
    # 1. Initialize the camera
    print("Initializing camera...")
    cap = cv2.VideoCapture(0) # 0 is usually the default webcam

    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    print("Camera active. Press SPACE to capture or ESC to quit.")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame.")
            break

        # Display the preview
        cv2.imshow("Webcam Test - Press SPACE to Analyze", frame)

        key = cv2.waitKey(1)
        if key % 256 == 27: # ESC pressed
            print("Closing...")
            break
        elif key % 256 == 32: # SPACE pressed
            print("Capturing frame and sending to backend...")
            
            # 2. Encode frame as Base64
            _, buffer = cv2.imencode('.jpg', frame)
            img_base64 = base64.b64encode(buffer).decode('utf-8')

            # 3. Send to Backend
            try:
                response = requests.post(
                    API_URL, 
                    json={"image": img_base64},
                    headers={"Content-Type": "application/json"}
                )

                if response.status_code == 200:
                    data = response.json()
                    print("\n--- ANALYSIS RESULT ---")
                    print(f"Dominant Emotion: {data.get('dominant_emotion')}")
                    print(f"Confidence Score: {data.get('score', 0):.2f}")
                    if 'details' in data:
                        print("Full Profile:", json.dumps(data['details'], indent=2))
                    print("-----------------------\n")
                else:
                    print(f"Server Error: {response.status_code}")
                    print(response.text)
            except Exception as e:
                print(f"Connection Error: {e}")

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    capture_and_analyze()
