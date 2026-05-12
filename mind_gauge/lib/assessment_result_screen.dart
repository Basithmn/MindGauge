import 'package:flutter/material.dart';

import 'models.dart';
import 'ui_components.dart';
import 'services.dart';
import 'level2_adult_screen.dart';
import 'level2_adolescent_screen.dart';
import 'dashboard_screen.dart';

class AssessmentResultScreen extends StatelessWidget {
  final List<DomainScore> results;
  final UserProfile userProfile;
  final String? overallStatus;
  final Map<String, dynamic>? combinedReport;

  const AssessmentResultScreen({
    super.key,
    required this.results,
    required this.userProfile,
    this.overallStatus,
    this.combinedReport,
  });

  @override
  Widget build(BuildContext context) {
    final bool needsFollowUp = results.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- OVERALL CLINICAL STATUS HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "OVERALL CLINICAL STATUS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overallStatus ?? "Screening Complete",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Disclaimer: This assessment is not a clinical diagnosis.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // --- COMBINED HOLISTIC INSIGHT ---
            if (combinedReport != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "HOLISTIC AI INSIGHT",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      combinedReport?['holistic_insight'] ??
                          "Analyzing combined patterns...",
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.text,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Visual Sentiment:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${combinedReport?['visual_summary']?['dominant']?.toUpperCase() ?? 'N/A'}",
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (combinedReport?['visual_summary']?['profile'] !=
                                null) ...[
                              const SizedBox(height: 8),
                              ...(combinedReport?['visual_summary']?['profile']
                                      as Map<String, dynamic>)
                                  .entries
                                  .map(
                                    (e) => Text(
                                      "${e.key}: ${(e.value * 100).toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                  ,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

            Text(
              needsFollowUp
                  ? 'Further Assessment Recommended'
                  : '✅ Level 1 Check-In Complete',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: needsFollowUp ? const Color.fromARGB(255, 53, 214, 229) : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              needsFollowUp
                  ? 'Your responses indicate symptoms in the areas below that meet the threshold for clinical follow-up.'
                  : 'Your responses did not meet the clinical threshold for requiring further assessment at this time.',
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
            const Divider(height: 40, thickness: 1, color: AppColors.secondary),

            // --- DOMAIN RESULTS OR EMPTY STATE ---
            if (needsFollowUp) ...[
              const Text(
                'Take These Follow-Up Questionnaires:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 15),
              ...results
                  .map(
                    (score) => DomainResultCard(
                      score: score,
                      userProfile: userProfile,
                    ),
                  )
                  ,
            ] else
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Icon(
                      Icons.sentiment_satisfied_alt,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'All clear! Check in again when clinically indicated.',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            
            // Link to Moments Page
            Center(
              child: StyledButton(
                text: 'GO TO MOMENTS',
                onPressed: () {
                  // Navigate to Dashboard and switch to Moments tab (index 1)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainDashboard(
                        userProfile: userProfile,
                        initialIndex: 1, // 1 is the Moments tab
                      ),
                    ),
                    (route) => false,
                  );
                },
                color: const Color.fromARGB(255, 255, 183, 77), // Warm color for moments
              ),
            ),
            const SizedBox(height: 20),
          ], // Line 1987: Now cleanly closes the list
        ),
      ),
    );
  }
}

class DomainResultCard extends StatelessWidget {
  final DomainScore score;
  final UserProfile userProfile;

  const DomainResultCard({
    super.key,
    required this.score,
    required this.userProfile,
  });

  Color _getSeverityColor(int scoreValue) {
    if (scoreValue >= 4) return const Color.fromARGB(255, 53, 185, 229);
    if (scoreValue == 3 || scoreValue == 2) return const Color.fromARGB(255, 0, 234, 255);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(score.highestScore);
    final isLevel2Available = score.Level2AdultMeasure != 'None';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: severityColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt, color: severityColor),
              const SizedBox(width: 8),
              // FIX: Wrapped in Expanded to prevent the "RenderFlex overflowed" error
              Expanded(
                child: Text(
                  '${score.domainName} (${score.severity})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI ANALYSIS BOX - Displays Level 2 LGBM Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ML-DRIVEN DIAGNOSIS:",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score.mlDiagnosis ?? "Analyzing patterns...",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Threshold Check Label
          Row(
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              // FIX: Wrapped in Flexible to prevent overflow on small screens
              Flexible(
                child: Text(
                  'Clinical Threshold Check: Highest Score ${score.highestScore} (Target >= ${score.thresholdScore})',
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (isLevel2Available)
            StyledButton(
              text: 'TAKE ${score.domainName.toUpperCase()} LEVEL 2 MEASURE',
              onPressed: () {
                final bool isAdolescent =
                    MockQuestionnaireService.mapAgeToQuestionnaire(
                      userProfile.age,
                    ) ==
                    QuestionnaireType.adolescentLevel1;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => isAdolescent
                        ? Level2AdolescentQuestionnaireScreen(
                            domainScore: score,
                            userProfile: userProfile,
                          )
                        : Level2AdultQuestionnaireScreen(
                            domainScore: score,
                            userProfile: userProfile,
                          ),
                  ),
                );
              },
              color: AppColors.secondary,
            )
          else
            Text(
              'No dedicated Level 2 measure is available for ${score.domainName}.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.text.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}
