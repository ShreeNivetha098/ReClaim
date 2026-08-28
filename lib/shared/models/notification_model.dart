import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // POTENTIAL_MATCH, CLAIM_SUBMITTED, CLAIM_APPROVED, CLAIM_REJECTED, NEW_MESSAGE, ITEM_RETURNED
  final String targetId; // itemId, claimId, or chatId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'POTENTIAL_MATCH',
      targetId: map['targetId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
