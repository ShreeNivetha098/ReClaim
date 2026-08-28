import 'package:cloud_firestore/cloud_firestore.dart';

class LostItemModel {
  final String id;
  final String ownerId;
  final String itemName;
  final String category;
  final String description;
  final String brand;
  final String colour;
  final DateTime dateLost;
  final String locationLost;
  final String approximateValue;
  final String? imageUrl;
  final String status; // ACTIVE, MATCHED, CLAIMED, RETURNED, CLOSED
  final DateTime createdAt;
  final DateTime updatedAt;

  LostItemModel({
    required this.id,
    required this.ownerId,
    required this.itemName,
    required this.category,
    required this.description,
    required this.brand,
    required this.colour,
    required this.dateLost,
    required this.locationLost,
    required this.approximateValue,
    this.imageUrl,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return LostItemModel(
      id: docId,
      ownerId: map['ownerId'] ?? '',
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      colour: map['colour'] ?? '',
      dateLost: map['dateLost'] is Timestamp
          ? (map['dateLost'] as Timestamp).toDate()
          : DateTime.tryParse(map['dateLost']?.toString() ?? '') ?? DateTime.now(),
      locationLost: map['locationLost'] ?? '',
      approximateValue: map['approximateValue'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'ACTIVE',
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
      'ownerId': ownerId,
      'itemName': itemName,
      'category': category,
      'description': description,
      'brand': brand,
      'colour': colour,
      'dateLost': Timestamp.fromDate(dateLost),
      'locationLost': locationLost,
      'approximateValue': approximateValue,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LostItemModel copyWith({
    String? id,
    String? ownerId,
    String? itemName,
    String? category,
    String? description,
    String? brand,
    String? colour,
    DateTime? dateLost,
    String? locationLost,
    String? approximateValue,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LostItemModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      colour: colour ?? this.colour,
      dateLost: dateLost ?? this.dateLost,
      locationLost: locationLost ?? this.locationLost,
      approximateValue: approximateValue ?? this.approximateValue,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
