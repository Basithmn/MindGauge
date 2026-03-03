import requests
import base64
import os

BASE_URL = "http://localhost:5000"

def test_combined_report():
    print("Testing /combined_report...")
    payload = {
        "questionnaire_results": [
            {"domainName": "Depression", "highestScore": 4, "mlDiagnosis": "Severe"},
            {"domainName": "Anxiety", "highestScore": 3, "mlDiagnosis": "Moderate"}
        ],
        "visual_sentiment": {
            "dominant_emotion": "sadness",
            "visual_sentiment_profile": {"sadness": 0.6, "happiness": 0.1, "neutral": 0.3},
            "overall_score": 0.6
        }
    }
    response = requests.post(f"{BASE_URL}/combined_report", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 200
    assert "Visual indicators align" in response.json()['holistic_insight']

if __name__ == "__main__":
    # Note: Requires the Flask server to be running
    try:
        test_combined_report()
        print("\nAll tests passed (Combined Report)!")
    except Exception as e:
        print(f"Test failed: {e}")
        print("Make sure the server is running at http://localhost:5000")
