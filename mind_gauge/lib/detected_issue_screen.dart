import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ui_components.dart';
class DetectedIssueScreen extends StatelessWidget {
  const DetectedIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue History'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Get assessments ordered by newest first
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('assessments')
            .orderBy('clientTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No issues detected yet."));
          }

          final latestDoc = snapshot.data!.docs.first;
          final List issues = latestDoc['issues'] ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              final color = (issue['score'] as int) >= 3 ? const Color.fromARGB(255, 0, 195, 255) : const Color.fromARGB(255, 0, 200, 183);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue['domainName'], 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text('Severity: ${issue['severity']}'),
                    Text('Recommendation: ${issue['followUp']}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}