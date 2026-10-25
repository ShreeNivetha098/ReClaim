import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single activity log entry for the admin dashboard.
/// Stored in the `activityLogs` Firestore collection.
class ActivityLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String action; // e.g. CLAIM_APPROVED, ITEM_REPORTED, USER_DEACTIVATED
  final String targetType; // e.g. claim, lostItem, foundItem, user
  final String targetId;
  final String details;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.details = '',
    required this.timestamp,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return ActivityLogModel(
      id: docId,
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      details: map['details'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
