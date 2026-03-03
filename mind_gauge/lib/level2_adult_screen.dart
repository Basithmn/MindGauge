import 'package:flutter/material.dart';
import 'models.dart';
import 'level2_result_screen.dart';
import 'questionnaire_screen.dart';
import 'services.dart';
import 'ui_components.dart';

class Level2AdultQuestionnaireScreen extends StatefulWidget {
  final DomainScore domainScore;
  final UserProfile userProfile;
  const Level2AdultQuestionnaireScreen({
    super.key,
    required this.domainScore,
    required this.userProfile,
  });
  @override
  State<Level2AdultQuestionnaireScreen> createState() =>
      _Level2AdultQuestionnaireScreenState();
}

class _Level2AdultQuestionnaireScreenState
    extends State<Level2AdultQuestionnaireScreen> {
  // Use an empty list as a default if the domain is not found
  late final List<Level2AdultQuestionnaireData> _questions;

  @override
  void initState() {
    super.initState();
    // Correctly access the Level 2 questions map using the domainName string key
    _questions = MockQuestionnaireService.getAdultLevel2Questions(
      widget.domainScore.domainName,
    );

    if (_questions.isEmpty) {
      // Show a message if no questions are found.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: No Level 2 questions found for ${widget.domainScore.domainName}.",
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.domainScore.domainName} Level 2'),
          backgroundColor: AppColors.secondary,
        ),
        body: const Center(
          child: Text("Level 2 Questionnaire not available (Mock Data Error)."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.domainScore.domainName} Level 2 Assessment'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow-up: ${widget.domainScore.Level2AdultMeasure}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Level 1 score was ${widget.domainScore.highestScore} (${widget.domainScore.severity}). Please complete this focused Level 2 measure:',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 30),

            // Display the Level 2 Questionnaire items using the shared widget
            ..._questions.asMap().entries.map(
              (entry) =>
                  QuestionnaireItem(data: entry.value, index: entry.key + 1),
            ),

            const SizedBox(height: 40),
            Center(
              child: StyledButton(
                text: 'SUBMIT LEVEL 2 ASSESSMENT',
                onPressed: () async {
                  // 1. Collect scores
                  final List<int> scores = _questions
                      .map((q) => q.score.round())
                      .toList();

                  // 2. Call ML Service
                  // Note: We use the adult/child logic inside the function,
                  // but this screen is specific to adults, so age is effectively >= 18.
                  final diagnosis = await getLevel2MLDiagnosis(
                    widget.domainScore.domainName,
                    scores,
                    widget.userProfile.age,
                  );

                  if (!context.mounted) return;

                  // 3. Navigate to Results Screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => Level2ResultScreen(
                        domainName: widget.domainScore.domainName,
                        diagnosis: diagnosis ?? "Could not analyze",
                        scores: scores,
                        userProfile: widget.userProfile,
                      ),
                    ),
                  );
                },
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
