import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;
  final DateTime? createdAt;
  final String? contentId;
  final String? contentType; // 'movie' ou 'tv'
  final String? type; // 'movie', 'series', 'product', 'custom'
  final String? overview;
  final double? rating;
  final String? backdropPath;

  Promotion({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.isActive,
    this.createdAt,
    this.contentId,
    this.contentType,
    this.type,
    this.overview,
    this.rating,
    this.backdropPath,
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
      contentId: data['contentId']?.toString(),
      contentType: data['contentType']?.toString(),
      type: data['type']?.toString(),
      overview: data['overview']?.toString() ?? data['description']?.toString(),
      rating: data['rating'] != null 
          ? (data['rating'] as num).toDouble() 
          : (data['voteAverage'] != null ? (data['voteAverage'] as num).toDouble() : null),
      backdropPath: data['backdropPath']?.toString(),
    );
  }

  Promotion copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? targetUrl,
    bool? isActive,
    DateTime? createdAt,
    String? contentId,
    String? contentType,
    String? type,
    String? overview,
    double? rating,
    String? backdropPath,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      type: type ?? this.type,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      backdropPath: backdropPath ?? this.backdropPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'contentId': contentId,
      'contentType': contentType,
      'type': type,
      'overview': overview,
      'rating': rating,
      'backdropPath': backdropPath,
    };
  }
}
