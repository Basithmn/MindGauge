import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ui_components.dart';
class RiskTrendsScreen extends StatelessWidget {
  const RiskTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Trends'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch the last 10 assessments to calculate a trend
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('assessments')
            .orderBy('clientTimestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No assessment data found.\nComplete a check-in to see trends.'),
            );
          }

          final docs = snapshot.data!.docs;
          
          // Calculate average risk score from historical data
          double totalScore = 0;
          int issueCount = 0;

          for (var doc in docs) {
            final List issues = doc['issues'] ?? [];
            for (var issue in issues) {
              totalScore += (issue['score'] as num).toDouble();
              issueCount++;
            }
          }

          double avgRisk = issueCount > 0 ? totalScore / issueCount : 0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendCard(avgRisk),
                const SizedBox(height: 30),
                const Text(
                  'Historical Context',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                const SizedBox(height: 10),
                _buildNarrative(avgRisk),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendCard(double avg) {
    String label = avg > 2.5 ? 'High Risk' : (avg > 1.0 ? 'Moderate' : 'Stable');
    Color color = avg > 2.5 ? AppColors.danger : (avg > 1.0 ? AppColors.warning : AppColors.primary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text('Aggregate Severity', style: TextStyle(color: AppColors.secondary)),
          Text(label, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          // Visual Progress Bar
          LinearProgressIndicator(
            value: (avg / 4).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            color: color,
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildNarrative(double avg) {
    String text = avg > 2.5 
      ? "Trends indicate persistent symptoms meeting clinical thresholds. Prioritize a professional consultation."
      : "Your symptoms appear to be fluctuating within a manageable range. Continue regular monitoring.";
      
    return Text(text, style: const TextStyle(fontSize: 16, height: 1.5));
  }
}