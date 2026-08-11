import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;
  final DateTime? createdAt;

  Promotion({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
