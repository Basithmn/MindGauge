import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class UserProfile {
  final String email;
  final String name;
  final String userId;
  final int age;
  final String location;

  UserProfile({required this.email, required this.name, required this.userId, required this.age, required this.location});

  factory UserProfile.fromDatabase(Map<String, dynamic> data, User user) {
    return UserProfile(
      email: user.email ?? '',
      name: data['name'] as String,
      userId: user.uid,
      age: data['age'] as int,
      location: data['location'] as String,
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final String phone;
  final String location; // 1. Add this field

  Professional({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.phone,
    required this.location, // 2. Update constructor
  });

  factory Professional.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Professional(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      hospital: data['hospital'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? 'Unknown', // 3. Map it from Firestore
    );
  }
}
class DomainScore {
  final String domain;
  final String domainName;
  final int highestScore;
  final int thresholdScore; 
  final String Level2AdultMeasure;
  String? mlDiagnosis; // The "source of truth" from your Python server

  DomainScore(
    this.domain, 
    this.domainName, 
    this.highestScore, 
    this.thresholdScore, 
    this.Level2AdultMeasure
  );

  // CHANGE: The UI now depends on the ML result
  String get severity {
    if (mlDiagnosis != null && mlDiagnosis!.isNotEmpty) {
      return mlDiagnosis!; // Return the actual LightGBM prediction
    }
    
    // Local fallback only if the ML server is unreachable
    switch (highestScore) {
      case 4: return "Severe";
      case 3: return "Moderate";
      case 2: return "Mild";
      case 1: return "Slight";
      default: return "None";
    }
  }

  @override
  String toString() {
    return "$domainName: $severity";
  }
}
class SentimentResult {
  final String emoji;
  final double score; // e.g., -1.0 (very negative) to 1.0 (very positive)
  final String description;

  const SentimentResult(this.emoji, this.score, this.description);
}

class JournalEntry {
  final DateTime date;
  final String text;
  final SentimentResult sentiment;

  JournalEntry({
    required this.date,
    required this.text,
    required this.sentiment,
  });
}
class DomainMetadata {
  final String domainName;
  final int thresholdScore; 
  final String Level2AdultMeasure;

  const DomainMetadata(this.domainName, this.thresholdScore, this.Level2AdultMeasure);
}


abstract class BaseQuestionnaireData {
  final String domain;
  final String questionNumber;
  final String questionText;
  double score;

  BaseQuestionnaireData({
    required this.domain, 
    required this.questionNumber, 
    required this.questionText, 
    required this.score,
  });
}

class QuestionnaireData extends BaseQuestionnaireData {
  QuestionnaireData(String domain, String questionNumber, String questionText) : super(
    domain: domain, 
    questionNumber: questionNumber, 
    questionText: questionText, 
    score: 0.0
  );
}

class Level2AdultQuestionnaireData extends BaseQuestionnaireData {
  Level2AdultQuestionnaireData(String domain, String questionNumber, String questionText) : super(
    domain: domain, 
    questionNumber: questionNumber, 
    questionText: questionText, 
    score: 0.0
  );
}
class Level2AdolescentQuestionnaireData extends BaseQuestionnaireData {
  Level2AdolescentQuestionnaireData(String domain, String questionNumber, String questionText) : super(
    domain: domain, 
    questionNumber: questionNumber, 
    questionText: questionText, 
    score: 0.0
  );
}

// NEW ENUM: Define types for age-based mapping
enum QuestionnaireType { adultLevel1, adolescentLevel1 }

