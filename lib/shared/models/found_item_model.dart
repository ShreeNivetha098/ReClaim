import 'package:cloud_firestore/cloud_firestore.dart';

class FoundItemModel {
  final String id;
  final String finderId;
  final String itemName;
  final String category;
  final String description;
  final String brand;
  final String colour;
  final DateTime dateFound;
  final String locationFound;
  final String imageUrl; // Required for found items
  final String currentHolder;
  final bool securityOfficeSubmitted;
  final String status; // ACTIVE, MATCHED, CLAIMED, RETURNED, CLOSED
  final DateTime createdAt;
  final DateTime updatedAt;

  FoundItemModel({
    required this.id,
    required this.finderId,
    required this.itemName,
    required this.category,
    required this.description,
    required this.brand,
    required this.colour,
    required this.dateFound,
    required this.locationFound,
    required this.imageUrl,
    this.currentHolder = '',
    this.securityOfficeSubmitted = false,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoundItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return FoundItemModel(
      id: docId,
      finderId: map['finderId'] ?? '',
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      colour: map['colour'] ?? '',
      dateFound: map['dateFound'] is Timestamp
          ? (map['dateFound'] as Timestamp).toDate()
          : DateTime.tryParse(map['dateFound']?.toString() ?? '') ?? DateTime.now(),
      locationFound: map['locationFound'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      currentHolder: map['currentHolder'] ?? '',
      securityOfficeSubmitted: map['securityOfficeSubmitted'] ?? false,
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
      'finderId': finderId,
      'itemName': itemName,
      'category': category,
      'description': description,
      'brand': brand,
      'colour': colour,
      'dateFound': Timestamp.fromDate(dateFound),
      'locationFound': locationFound,
      'imageUrl': imageUrl,
      'currentHolder': currentHolder,
      'securityOfficeSubmitted': securityOfficeSubmitted,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FoundItemModel copyWith({
    String? id,
    String? finderId,
    String? itemName,
    String? category,
    String? description,
    String? brand,
    String? colour,
    DateTime? dateFound,
    String? locationFound,
    String? imageUrl,
    String? currentHolder,
    bool? securityOfficeSubmitted,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoundItemModel(
      id: id ?? this.id,
      finderId: finderId ?? this.finderId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      colour: colour ?? this.colour,
      dateFound: dateFound ?? this.dateFound,
      locationFound: locationFound ?? this.locationFound,
      imageUrl: imageUrl ?? this.imageUrl,
      currentHolder: currentHolder ?? this.currentHolder,
      securityOfficeSubmitted:
          securityOfficeSubmitted ?? this.securityOfficeSubmitted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
