import 'package:cloud_firestore/cloud_firestore.dart';

class MovieRequest {
  final String id;
  final String title;
  final String type; // 'movie' ou 'series'
  final String? year;
  final String? notes;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String status; // 'pending', 'in_review', 'added', 'rejected'
  final String? adminFeedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MovieRequest({
    required this.id,
    required this.title,
    this.type = 'movie',
    this.year,
    this.notes,
    this.userId,
    this.userName,
    this.userEmail,
    this.status = 'pending',
    this.adminFeedback,
    this.createdAt,
    this.updatedAt,
  });

  bool get isMovie => type == 'movie';
  bool get isSeries => type == 'series';

  String get typeLabel => isMovie ? 'Filme' : 'Série';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'in_review':
        return 'Em Análise';
      case 'added':
        return 'Adicionado';
      case 'rejected':
        return 'Recusado';
      default:
        return 'Pendente';
    }
  }

  factory MovieRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MovieRequest.fromJson(data, docId: doc.id);
  }

  factory MovieRequest.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return MovieRequest(
      id: docId ?? (json['id'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      year: json['year']?.toString(),
      notes: json['notes'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminFeedback: json['adminFeedback'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      if (year != null && year!.isNotEmpty) 'year': year,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      'status': status,
      if (adminFeedback != null) 'adminFeedback': adminFeedback,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MovieRequest copyWith({
    String? id,
    String? title,
    String? type,
    String? year,
    String? notes,
    String? userId,
    String? userName,
    String? userEmail,
    String? status,
    String? adminFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MovieRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      year: year ?? this.year,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
