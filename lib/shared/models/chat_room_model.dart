import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoomModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRoomModel(
      id: docId,
      itemId: map['itemId'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastMessageTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }
}
