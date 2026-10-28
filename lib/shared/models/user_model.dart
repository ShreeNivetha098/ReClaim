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

  /// College ID verification: NONE, PENDING, VERIFIED or REJECTED.
  final String verificationStatus;
  final String? verifiedBy; // admin's name
  final DateTime? verifiedAt;
  final String? verificationNote; // reason, when rejected

  bool get isVerified => verificationStatus == 'VERIFIED';

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
    this.verificationStatus = 'NONE',
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNote,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      role: (map['role']?.toString().trim()) ?? (map['Role']?.toString().trim()) ?? 'Student',
      profileImage: map['profileImage'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      verificationStatus: map['verificationStatus']?.toString() ?? 'NONE',
      verifiedBy: map['verifiedBy'],
      verifiedAt: map['verifiedAt'] is Timestamp ? (map['verifiedAt'] as Timestamp).toDate() : null,
      verificationNote: map['verificationNote'],
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
      'verificationStatus': verificationStatus,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
      'verificationNote': verificationNote,
    };
  }

  /// Sets all verification fields at once, so earlier values can be cleared.
  UserModel withVerification({
    required String status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? note,
  }) {
    return UserModel.fromMap({
      ...toMap(),
      'verificationStatus': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt),
      'verificationNote': note,
    }, uid);
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
    String? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? verificationNote,
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
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }
}
