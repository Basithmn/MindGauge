import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';

import 'models.dart';
import 'services.dart';
import 'ui_components.dart';
import 'services/camera_service.dart';
import 'assessment_result_screen.dart';
class QuestionnaireScreen extends StatefulWidget {
  // FIX: Re-introduced userAge parameter
  final int userAge;
  const QuestionnaireScreen({super.key, required this.userAge});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // FIX: Use late initialization and MockService to fetch age-based questions
  late final List<QuestionnaireData> _questions;
  final MockQuestionnaireService _service = MockQuestionnaireService();
  bool _isLoading = false;
  
  // Camera & Emotion Analysis
  final CameraService _cameraService = CameraService();
  String _currentEmotion = "";

  @override
  void initState() {
    super.initState();
    _questions = MockQuestionnaireService.getLevel1Questions(widget.userAge);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    if (_cameraService.isInitialized) {
      await _cameraService.startVideoRecording();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (!_cameraService.isInitialized) return;

    // Optional: Throttle or limit frequency if needed
    final image = await _cameraService.takePicture();
    if (image != null) {
      final result = await _cameraService.analyzeExpression(image);
      if (result != null && mounted) {
        setState(() {
          _currentEmotion = "${result['dominant_emotion']} (${(result['score'] * 100).toStringAsFixed(1)}%)";
        });
        print("Detected Emotion: $_currentEmotion");
        // TODO: Store this emotion data alongside the specific question response if needed
      }
    }
  }

void _handleSubmit() async {
  setState(() { _isLoading = true; });

  // 1. Stop Video Recording and Analyze
  Map<String, dynamic>? visualSentiment;
  XFile? videoFile = await _cameraService.stopVideoRecording();
  if (videoFile != null) {
    visualSentiment = await _cameraService.analyzeVideo(videoFile);
  }

  // 2. Prepare 13 Domain Scores for the Gatekeeper model
  final List<int> thirteenDomainScores = [
    _getHighestScoreForDomain("I"),    // Depression
    _getHighestScoreForDomain("II"),   // Anger
    _getHighestScoreForDomain("III"),  // Mania
    _getHighestScoreForDomain("IV"),   // Anxiety
    _getHighestScoreForDomain("V"),    // Somatic
    _getHighestScoreForDomain("VIII"), // Sleep
    _getHighestScoreForDomain("X"),    // Repetitive Thoughts
    _getHighestScoreForDomain("XIII"), // Substance Use
    _getHighestScoreForDomain("VI"),   // Suicidal
    _getHighestScoreForDomain("VII"),  // Psychosis
    _getHighestScoreForDomain("IX"),   // Memory
    _getHighestScoreForDomain("XI"),   // Dissociation
    _getHighestScoreForDomain("XII"),  // Personality Functioning
  ];

  // 3. Call Global Level 1 Diagnostic Model
  String? overallStatus = await getMLDiagnosis("level1", thirteenDomainScores, widget.userAge);

  // 4. Identify domains requiring categorical severity analysis
  final List<DomainScore> categoricalResults = await _service.submitQuestionnaire(_questions, widget.userAge);
  final List<int> rawScores = _questions.map((q) => q.score.round()).toList();

// 5. Fetch specific severity labels from ML categorical models (PARALLEL & FIXED)
  final List<Map<String, dynamic>> serializedResults = [];

  // Create all tasks at once
  final diagnosisFutures = categoricalResults.map((res) async {
    try {
      // Pass the rawScores; getMLDiagnosis handles the sublist/slicing
      String? categoricalSeverity = await getMLDiagnosis(res.domainName, rawScores, widget.userAge)
          .timeout(const Duration(seconds: 10)); // Prevent infinite hang
      
      res.mlDiagnosis = categoricalSeverity ?? "Clinical Review Required"; 

      // Dart's list.add is safe here because of the single-threaded event loop
      serializedResults.add({
        'domainName': res.domainName,
        'highestScore': res.highestScore,
        'mlDiagnosis': res.mlDiagnosis,
      });
    } catch (e) {
      print("Error diagnosing ${res.domainName}: $e");
      res.mlDiagnosis = "Analysis Unavailable";
    }
  }).toList();

  // Wait for all requests to finish at the same time
  await Future.wait(diagnosisFutures);
  // 6. Get Combined Holistic Report
  Map<String, dynamic>? combinedReport;
  if (visualSentiment != null) {
    combinedReport = await _cameraService.getCombinedReport(serializedResults, visualSentiment);
  }

  // 7. Save everything to Firestore
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseUserService().saveAssessmentResults(
      user.uid, 
      categoricalResults, 
      overallStatus
    );
  }

  setState(() { _isLoading = false; });
  if (!mounted) return;

  // 8. Navigate to Results
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AssessmentResultScreen(
        results: categoricalResults, 
        userAge: widget.userAge,
        overallStatus: overallStatus, 
        combinedReport: combinedReport,
      ),
    ),
  );
}

// Helper to find the maximum score for a given domain ID (e.g., "I", "VII")
int _getHighestScoreForDomain(String domainId) {
  final domainQuestions = _questions.where((q) => q.domain == domainId);
  if (domainQuestions.isEmpty) return 0;
  return domainQuestions.map((q) => q.score.round()).reduce((a, b) => a > b ? a : b);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level 1 Symptom Check-In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentEmotion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(child: Text(_currentEmotion, style: const TextStyle(fontSize: 12))),
            ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu tapped: Detected Issue, Trends, etc.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe Camera Preview (Small debug view)
             if (_cameraService.isInitialized && _cameraService.controller != null)
              Container(
                height: 1, 
                width: 1, 
                child: CameraPreview(_cameraService.controller!), // Hidden but active
              ),

            Text(
              'Questionnaire Version: ${MockQuestionnaireService.mapAgeToQuestionnaire(widget.userAge).toString().split('.').last}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rate how much or how often you have been bothered by each problem during the past TWO (2) WEEKS.'),
                  SizedBox(height: 10),
                  Text('Response Scale:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('0 - None/Not at all'),
                  Text('1 - Slight (Rare, less than a day or two)'),
                  Text('2 - Mild (Several days)'),
                  Text('3 - Moderate (More than half the days)'),
                  Text('4 - Severe (Nearly every day)'),
                ],
              ),
            ),
            ..._questions.asMap().entries.map((entry) =>
              QuestionnaireItem(
                data: entry.value, 
                index: entry.key + 1,
                onInteraction: _captureAndAnalyze, // Bind callback
              )),
            const SizedBox(height: 40),
            Center(
              child: _isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : StyledButton(
                    text: 'SUBMIT ASSESSMENT',
                    onPressed: _handleSubmit,
                  ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
// 6. QUESTIONNAIRE WIDGET & SCREEN
class QuestionnaireItem extends StatefulWidget {
  final BaseQuestionnaireData data; 
  final int index;
  final VoidCallback? onInteraction; // New callback

  const QuestionnaireItem({
    super.key, 
    required this.data, 
    required this.index,
    this.onInteraction,
  });

  @override
  State<QuestionnaireItem> createState() => _QuestionnaireItemState();
}

class _QuestionnaireItemState extends State<QuestionnaireItem> {
  int get sliderValue => widget.data.score.round();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.data.questionNumber}. ${widget.data.questionText}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.secondary),
                onPressed: () {
                  if (widget.data.score > 0) {
                    setState(() {
                      widget.data.score--;
                    });
                    widget.onInteraction?.call(); // Trigger capture
                  }
                },
              ),
              Expanded(
                child: Slider(
                  value: widget.data.score,
                  min: 0,
                  max: 4,
                  divisions: 4,
                  label: sliderValue.toString(),
                  onChanged: (double value) {
                    setState(() {
                      widget.data.score = value;
                    });
                    widget.onInteraction?.call(); // Trigger capture
                  },
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
              Text(
                sliderValue.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.secondary),
                onPressed: () {
                  if (widget.data.score < 4) {
                    setState(() {
                      widget.data.score++;
                    });
                    widget.onInteraction?.call(); // Trigger capture
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}