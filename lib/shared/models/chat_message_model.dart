import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
