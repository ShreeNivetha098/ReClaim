import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String rollNumber;
  final String role; // Student, Faculty, Staff, Admin
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.rollNumber,
    required this.role,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      role: map['role'] ?? 'Student',
      profileImage: map['profileImage'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'rollNumber': rollNumber,
      'role': role,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? rollNumber,
    String? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
