import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  registrationCreated,
  registrationApproved,
  registrationRejected,
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type; // 'registration_created', 'registration_approved', 'registration_rejected'
  final Map<String, dynamic>? data; // {registrationId, visitorName, reason}
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final docData = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: docData['recipientId'] ?? '',
      title: docData['title'] ?? '',
      message: docData['message'] ?? '',
      type: docData['type'] ?? 'registration_created',
      data: docData['data'] as Map<String, dynamic>?,
      read: docData['read'] ?? false,
      createdAt: (docData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  String? get registrationId => data?['registrationId'] as String?;
  String? get visitorName => data?['visitorName'] as String?;
  String? get reason => data?['reason'] as String?;
}
