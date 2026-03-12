import 'package:flutter/material.dart';
import 'ui_components.dart';
import 'questionnaire_screen.dart';
import 'models.dart';

class CheckInTab extends StatelessWidget {
  final UserProfile userProfile;
  final Function(List<DomainScore>)? onCheckInComplete;

  const CheckInTab({
    super.key,
    required this.userProfile,
    this.onCheckInComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Take a quick symptom check-in to get personalized advice and track your mental well-being over time.',
                style: TextStyle(fontSize: 16, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              StyledButton(
                text: 'Start Symptom Check-In',
                onPressed: () async {
                  final results = await Navigator.of(context).push<
                    List<DomainScore>
                  >(
                    MaterialPageRoute(
                      builder:
                          (context) => QuestionnaireScreen(
                            userProfile: userProfile,
                          ),
                    ),
                  );

                  if (results != null && onCheckInComplete != null) {
                    onCheckInComplete!(results);
                  }
                },
                color: AppColors.primary,
                shadowColor: AppColors.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
