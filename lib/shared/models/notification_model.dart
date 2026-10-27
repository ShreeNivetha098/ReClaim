import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // COMMON, POTENTIAL_MATCH, CLAIM_SUBMITTED, CLAIM_APPROVED, CLAIM_REJECTED, NEW_MESSAGE, ITEM_RETURNED
  final String targetId; // itemId, claimId, or chatId
  final String? itemType; // LOST, FOUND, or null
  final String? lostItemId; // for POTENTIAL_MATCH: the recipient's lost report
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    this.itemType,
    this.lostItemId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '',
      type: map['type'] ?? 'COMMON',
      targetId: map['targetId'] ?? map['itemId'] ?? '',
      itemType: map['itemType'],
      lostItemId: map['lostItemId'],
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
      'recipientId': userId,
      'title': title,
      'body': body,
      'message': body,
      'type': type,
      'targetId': targetId,
      'itemId': targetId,
      if (itemType != null) 'itemType': itemType,
      if (lostItemId != null) 'lostItemId': lostItemId,
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
    String? itemType,
    String? lostItemId,
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
      itemType: itemType ?? this.itemType,
      lostItemId: lostItemId ?? this.lostItemId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
