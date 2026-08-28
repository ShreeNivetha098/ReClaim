import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String itemId;
  final String lostItemId;
  final String foundItemId;
  final String claimantId;
  final String verificationAnswer;
  final String uniqueMarks;
  final String contentsInside;
  final String additionalInfo;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime createdAt;
  final DateTime updatedAt;

  ClaimModel({
    required this.id,
    required this.itemId,
    required this.lostItemId,
    required this.foundItemId,
    required this.claimantId,
    required this.verificationAnswer,
    this.uniqueMarks = '',
    this.contentsInside = '',
    this.additionalInfo = '',
    this.status = 'PENDING',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClaimModel(
      id: docId,
      itemId: map['itemId'] ?? map['foundItemId'] ?? '',
      lostItemId: map['lostItemId'] ?? '',
      foundItemId: map['foundItemId'] ?? '',
      claimantId: map['claimantId'] ?? '',
      verificationAnswer: map['verificationAnswer'] ?? '',
      uniqueMarks: map['uniqueMarks'] ?? '',
      contentsInside: map['contentsInside'] ?? '',
      additionalInfo: map['additionalInfo'] ?? '',
      status: map['status'] ?? 'PENDING',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'lostItemId': lostItemId,
      'foundItemId': foundItemId,
      'claimantId': claimantId,
      'verificationAnswer': verificationAnswer,
      'uniqueMarks': uniqueMarks,
      'contentsInside': contentsInside,
      'additionalInfo': additionalInfo,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ClaimModel copyWith({
    String? id,
    String? itemId,
    String? lostItemId,
    String? foundItemId,
    String? claimantId,
    String? verificationAnswer,
    String? uniqueMarks,
    String? contentsInside,
    String? additionalInfo,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      lostItemId: lostItemId ?? this.lostItemId,
      foundItemId: foundItemId ?? this.foundItemId,
      claimantId: claimantId ?? this.claimantId,
      verificationAnswer: verificationAnswer ?? this.verificationAnswer,
      uniqueMarks: uniqueMarks ?? this.uniqueMarks,
      contentsInside: contentsInside ?? this.contentsInside,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
