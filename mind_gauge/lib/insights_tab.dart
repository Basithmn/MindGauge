import 'package:flutter/material.dart';
import 'ui_components.dart';
import 'recommendations_screen.dart';
import 'detected_issue_screen.dart';
import 'risk_trends_screen.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'TRACK YOUR WELL-BEING',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          _InsightCard(
            title: 'Recommendations',
            icon: Icons.lightbulb,
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecommendationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _InsightCard(
            title: 'Detected Issues',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DetectedIssueScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _InsightCard(
            title: 'Risk Trends',
            icon: Icons.trending_up,
            color: AppColors.secondary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RiskTrendsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.text, size: 16),
          ],
        ),
      ),
    );
  }
}
