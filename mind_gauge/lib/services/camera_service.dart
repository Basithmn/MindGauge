import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _sending = false; 
  // API Endpoint Route mapping based on platform
  String get _apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    return 'http://172.16.7.248:5000';
  }

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller; // Expose controller for Preview widget

  Future<void> initialize() async {
    try {
      // 1. Request Permissions
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        print("Camera permission denied");
        return;
      }

      // 2. Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print("No cameras available");
        return;
      }

      // 3. Initialize controller (Use front camera by default)
      CameraDescription frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low, // Lower resolution for faster upload/processing
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      print("Camera initialized successfully");

    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null) return null;

    try {
      if (_controller!.value.isTakingPicture) return null; // Prevent overlap

      XFile image = await _controller!.takePicture();
      return image;
    } catch (e) {
      print("Error taking picture: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeExpression(XFile imageFile) async {
    if (_sending) return null;
    _sending = true;

    try {
      final bytes = await imageFile.readAsBytes();
      
      // Compress image significantly before sending to ML API
      List<int> compressedBytes = bytes;
      if (!kIsWeb) {
        try {
          compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 480,
            minHeight: 480,
            quality: 70,
          );
        } catch (e) {
          print("Compression failed, falling back to original: $e");
        }
      }

      final String base64Image = base64Encode(compressedBytes);

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/analyze_face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Emotion: ${data['dominant_emotion']}");
        return data;
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending image to API: $e");
    } finally {
      _sending = false;   // ← THIS IS CRITICAL
    }

    return null;
  }
  Future<void> startVideoRecording() async {
    if (!_isInitialized || _controller == null) return;
    try {
      if (_controller!.value.isRecordingVideo) return;
      await _controller!.startVideoRecording();
      print("Video recording started");
    } catch (e) {
      print("Error starting video recording: $e");
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!_isInitialized || _controller == null) return null;
    try {
      if (!_controller!.value.isRecordingVideo) return null;
      XFile video = await _controller!.stopVideoRecording();
      print("Video recording stopped: ${video.path}");
      return video;
    } catch (e) {
      print("Error stopping video recording: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeVideo(XFile videoFile) async {
    try {
      final bytes = await videoFile.readAsBytes();
      final String base64Video = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/analyze_video'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video': base64Video,
        }),
      ).timeout(const Duration(seconds: 15)); // A bit longer for videos if used again

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Video Analysis Dominant Emotion: ${data['dominant_emotion']}");
        return data;
      } else {
        print("Video API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error sending video to API: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCombinedReport(List<Map<String, dynamic>> questionnaireResults, Map<String, dynamic> visualSentiment) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/combined_report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'questionnaire_results': questionnaireResults,
          'visual_sentiment': visualSentiment,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Combined Report Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error getting combined report: $e");
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print("Error disposing camera: $e");
    } finally {
      _isInitialized = false;
      _cameras = null; // Release resources
    }
  }
}
