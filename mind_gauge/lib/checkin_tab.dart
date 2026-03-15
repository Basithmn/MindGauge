import 'package:flutter/material.dart';
import 'ui_components.dart';
import 'questionnaire_screen.dart';
import 'models.dart';
import 'services.dart';
import 'assessment_result_screen.dart'; // To reuse DomainResultCard

class CheckInTab extends StatefulWidget {
  final UserProfile userProfile;
  final Function(List<DomainScore>)? onCheckInComplete;

  const CheckInTab({
    super.key,
    required this.userProfile,
    this.onCheckInComplete,
  });

  @override
  State<CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends State<CheckInTab> {
  final FirebaseUserService _userService = FirebaseUserService();
  List<DomainScore> _pendingLevel2s = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingAssessments();
  }

  Future<void> _loadPendingAssessments() async {
    try {
      final data = await _userService.getLatestAssessment(widget.userProfile.userId);
      if (data != null && data['issues'] != null) {
        final List<dynamic> issues = data['issues'];
        final List<DomainScore> pending = [];
        
        for (var issue in issues) {
          final String followUp = issue['followUp'] ?? 'None';
          if (followUp != 'None') {
            final score = DomainScore(
              '', // Original domain code isn't preserved, but it's not needed for UI
              issue['domainName'] ?? 'Unknown',
              issue['score'] ?? 0,
              0, // Threshold not strictly needed here
              followUp,
            )..mlDiagnosis = issue['severity'];
            pending.add(score);
          }
        }
        
        if (mounted) {
          setState(() {
            _pendingLevel2s = pending;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error fetching latest assessment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
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
                          userProfile: widget.userProfile,
                        ),
                  ),
                );

                if (results != null && widget.onCheckInComplete != null) {
                  widget.onCheckInComplete!(results);
                }
              },
              color: AppColors.primary,
              shadowColor: AppColors.primary.withOpacity(0.5),
            ),
            
            const SizedBox(height: 40),
            
            if (_isLoading)
               const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            else if (_pendingLevel2s.isNotEmpty) ...[
               const Divider(height: 40, thickness: 1),
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text(
                   'Pending Follow-Up Assessments:',
                   style: TextStyle(
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                     color: AppColors.secondary,
                   ),
                 ),
               ),
               const SizedBox(height: 10),
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text(
                   'Based on your last check-in, the following deeper measures are recommended for you.',
                 ),
               ),
               const SizedBox(height: 20),
               ..._pendingLevel2s.map((score) => DomainResultCard(
                 score: score,
                 userProfile: widget.userProfile,
               )),
            ]
          ],
        ),
      ),
    );
  }
}
