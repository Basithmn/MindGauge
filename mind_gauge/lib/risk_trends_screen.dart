import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ui_components.dart';

class RiskTrendsScreen extends StatefulWidget {
  const RiskTrendsScreen({super.key});

  @override
  State<RiskTrendsScreen> createState() => _RiskTrendsScreenState();
}

class _RiskTrendsScreenState extends State<RiskTrendsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Trends'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('assessments')
              .orderBy('clientTimestamp', descending: true)
              .limit(20)
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('level2_assessments')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              (snapshot.data![0].docs.isEmpty &&
                  snapshot.data![1].docs.isEmpty)) {
            return const Center(
              child: Text(
                'No assessment data found.\nComplete a check-in to see trends.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final l1Docs = snapshot.data![0].docs;
          final l2Docs = snapshot.data![1].docs;

          List<_TrendSession> sessions = [];

          // 1. Process Level 1 docs
          for (var doc in l1Docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['clientTimestamp'] as Timestamp).toDate();
            final List issues = data['issues'] ?? [];
            if (issues.isNotEmpty) {
              double sessionSum = 0;
              for (var issue in issues) {
                sessionSum += (issue['score'] as num).toDouble();
              }
              sessions.add(
                _TrendSession(
                  timestamp: timestamp,
                  avgScore: sessionSum / issues.length,
                  isLevel2: false,
                ),
              );
            }
          }

          // 2. Process Level 2 docs
          for (var doc in l2Docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final List scores = data['scores'] ?? [];
            if (scores.isNotEmpty) {
              double sessionSum = 0;
              for (var s in scores) {
                sessionSum += (s as num).toDouble();
              }
              sessions.add(
                _TrendSession(
                  timestamp: timestamp,
                  avgScore: sessionSum / scores.length,
                  isLevel2: true,
                ),
              );
            }
          }

          // Sort chronologically
          sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Simple merging logic: If a Level 1 is followed by a Level 2 for the same day,
          // we could combine them. But for now, we'll just show them as a single progressive trend.
          // This naturally creates the "dip" the user expects.

          if (sessions.length > 10) {
            sessions = sessions.sublist(sessions.length - 10);
          }

          List<FlSpot> spots = [];
          for (int i = 0; i < sessions.length; i++) {
            spots.add(FlSpot(i.toDouble(), sessions[i].avgScore));
          }

          double currentAvg = sessions.isNotEmpty
              ? sessions.last.avgScore
              : 1.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Severity Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Prioritizing precision with clinical Level 2 data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                _buildChartContainer(spots, currentAvg),
                const SizedBox(height: 30),
                _buildSummaryCard(currentAvg),
                const SizedBox(height: 30),
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildNarrative(currentAvg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartContainer(List<FlSpot> spots, double risk) {
    if (spots.isEmpty) return const SizedBox.shrink();

    Color lineColor;
    if (risk > 3.5) {
      lineColor = AppColors.danger;
    } else if (risk > 2.5) {
      lineColor = AppColors.warning;
    } else {
      lineColor = AppColors.primary;
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Severity (1-5)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Assessment Sequence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  (value.toInt() + 1).toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble().clamp(5.0, 10.0),
          minY: 1,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double avg) {
    String label;
    Color color;

    if (avg > 3.5) {
      label = 'High Risk';
      color = AppColors.danger;
    } else if (avg > 2.5) {
      label = 'Moderate';
      color = AppColors.warning;
    } else if (avg > 1.5) {
      label = 'Low Risk';
      color = AppColors.primary;
    } else {
      label = 'Stable';
      color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Status',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: ((avg - 1) / 4).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrative(double avg) {
    String text = avg > 3.0
        ? "Trends indicate persistent symptoms meeting clinical thresholds. Prioritize a professional consultation to discuss these levels."
        : (avg > 1.5
              ? "Your symptoms appear to be fluctuating within a manageable range. Continue regular monitoring to track your wellness journey."
              : "Your symptoms are currently within a stable, healthy range. Keep up your wellness routine!");

    return Text(
      text,
      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
    );
  }
}

class _TrendSession {
  final DateTime timestamp;
  final double avgScore;
  final bool isLevel2;
  _TrendSession({
    required this.timestamp,
    required this.avgScore,
    required this.isLevel2,
  });
}
