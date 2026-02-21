import 'package:flutter/material.dart';
import 'questionnaire_screen.dart';
import 'models.dart';
import 'services.dart';
import 'ui_components.dart';
class Level2AdolescentQuestionnaireScreen extends StatefulWidget {
  final DomainScore domainScore;
  final int userAge;
  const Level2AdolescentQuestionnaireScreen({
    super.key,
    required this.domainScore,
    required this.userAge,
  });
  @override
  State<Level2AdolescentQuestionnaireScreen> createState() => _Level2AdolescentQuestionnaireScreenState();
}

class _Level2AdolescentQuestionnaireScreenState extends State<Level2AdolescentQuestionnaireScreen> {
  late final List<Level2AdolescentQuestionnaireData> _questions; 
  
  @override
  void initState() {
    super.initState();
    // Access the Adolescent Level 2 map
    _questions = MockQuestionnaireService.getAdolescentLevel2Questions(
      widget.domainScore.domainName,
    );
    
    if (_questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: No Adolescent Level 2 questions found for ${widget.domainScore.domainName}.")),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.domainScore.domainName} Level 2'), backgroundColor: AppColors.secondary),
        body: const Center(child: Text("Child Level 2 Questionnaire not available.")),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.domainScore.domainName} (Age 11-17)'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focused Follow-up Measure ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Based on your previous answers, please answer how much you have been bothered by these problems in the past 7 days. [cite: 5, 22, 33, 51, 60, 98]',
              style: TextStyle(fontSize: 16),
            ),
            const Divider(height: 30),
            ..._questions.asMap().entries.map((entry) =>
              QuestionnaireItem(data: entry.value, index: entry.key + 1)),
            const SizedBox(height: 40),
            Center(
              child: StyledButton(
                text: 'SUBMIT CHILD LEVEL 2',
                onPressed: () async {
                  // 1. Collect scores
                  final List<int> scores = _questions.map((q) => q.score.round()).toList();
                  
                  // 2. Call ML Service
                  // Note: We use the adult/child logic inside the function.
                  // This screen is specific to adolescents (11-17), so age < 18.
                  final diagnosis = await getLevel2MLDiagnosis(
                    widget.domainScore.domainName, 
                    scores, 
                    widget.userAge
                  );

                  if (!context.mounted) return;

                  // 3. Show Result
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('${widget.domainScore.domainName} Level 2 Result'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Based on your responses, the severity is:"),
                          const SizedBox(height: 10),
                          Text(
                            diagnosis ?? "Could not analyze",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Close dialog
                            Navigator.of(context).pop(); // Go back to dashboard/results
                          },
                          child: const Text("OK"),
                        )
                      ],
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