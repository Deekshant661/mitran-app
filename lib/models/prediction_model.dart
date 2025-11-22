import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionModel {
  final String? predictionId;
  final String imageUrl;
  final String label;
  final double confidence;
  final String title;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> homecare;
  final String note;
  final String userId;
  final DateTime timestamp;

  PredictionModel({
    this.predictionId,
    required this.imageUrl,
    required this.label,
    required this.confidence,
    required this.title,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.homecare,
    required this.note,
    required this.userId,
    required this.timestamp,
  });

  factory PredictionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionModel(
      predictionId: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      label: data['label'] ?? '',
      confidence: (data['confidence'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      treatments: List<String>.from(data['treatments'] ?? []),
      homecare: List<String>.from(data['homecare'] ?? []),
      note: data['note'] ?? '',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'label': label,
      'confidence': confidence,
      'title': title,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments,
      'homecare': homecare,
      'note': note,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}