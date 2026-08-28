import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/user_model.dart';
import '../../shared/models/lost_item_model.dart';
import '../../shared/models/found_item_model.dart';
import '../../shared/models/claim_model.dart';
import '../../shared/models/chat_message_model.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/notification_model.dart';
import 'firebase_service.dart';

class ReClaimRepository {
  static const _uuid = Uuid();

  // In-Memory state fallback when live Firebase configuration is pending
  UserModel? _currentUser;
  final List<UserModel> _mockUsers = [];
  final List<LostItemModel> _mockLostItems = [];
  final List<FoundItemModel> _mockFoundItems = [];
  final List<ClaimModel> _mockClaims = [];
  final List<ChatRoomModel> _mockChatRooms = [];
  final List<ChatMessageModel> _mockMessages = [];
  final List<NotificationModel> _mockNotifications = [];

  ReClaimRepository() {
    _seedInitialData();
  }

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> checkCurrentUser() async {
    if (FirebaseService.isInitialized) {
      final firebaseUser = FirebaseService.auth.currentUser;
      if (firebaseUser != null) {
        try {
          final doc = await FirebaseService.firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final user = UserModel.fromMap(doc.data()!, doc.id);
            _currentUser = user;
            return user;
          }
        } catch (e) {
          debugPrint('Error fetching current user profile: $e');
        }
      }
      _currentUser = null;
      return null;
    }
    return _currentUser;
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION OPERATIONS
  // ---------------------------------------------------------------------------

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String department,
    required String rollNumber,
    required String role,
  }) async {
    final now = DateTime.now();

    if (FirebaseService.isInitialized) {
      final credential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        department: department,
        rollNumber: rollNumber,
        role: role,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await FirebaseService.firestore.collection('users').doc(uid).set(newUser.toMap());
      _currentUser = newUser;
      return newUser;
    }

    // Local state execution
    final uid = _uuid.v4();
    final newUser = UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      department: department,
      rollNumber: rollNumber,
      role: role,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    _mockUsers.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    if (FirebaseService.isInitialized) {
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await FirebaseService.firestore.collection('users').doc(credential.user!.uid).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        _currentUser = user;
        return user;
      } else {
        throw Exception('User profile not found in Firestore.');
      }
    }

    // Local lookup
    final found = _mockUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => UserModel(
        uid: _uuid.v4(),
        name: email.split('@').first,
        email: email,
        phone: '+91 9876543210',
        department: 'Computer Science',
        rollNumber: 'MCA-2026-001',
        role: email.contains('admin') ? 'Admin' : 'Student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    _currentUser = found;
    return found;
  }

  Future<void> logoutUser() async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.auth.signOut();
    }
    _currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.auth.sendPasswordResetEmail(email: email);
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('users')
            .doc(updatedUser.uid)
            .update(updatedUser.toMap());
      } catch (e) {
        debugPrint('Update profile error: $e');
      }
    } else {
      final index = _mockUsers.indexWhere((u) => u.uid == updatedUser.uid);
      if (index != -1) {
        _mockUsers[index] = updatedUser;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE UPLOAD
  // ---------------------------------------------------------------------------

  Future<String?> uploadImage(File file, String folderPath) async {
    if (FirebaseService.isInitialized) {
      try {
        final fileName = '${_uuid.v4()}.jpg';
        final ref = FirebaseService.storage.ref().child('$folderPath/$fileName');
        final uploadTask = await ref.putFile(file);
        return await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Storage Upload Warning: $e');
      }
    }
    // Return sample visual image placeholder for immediate demo test
    return 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80';
  }

  // ---------------------------------------------------------------------------
  // LOST ITEMS OPERATIONS
  // ---------------------------------------------------------------------------

  Future<List<LostItemModel>> getLostItems() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('lostItems')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((doc) => LostItemModel.fromMap(doc.data(), doc.id)).toList();
      } catch (e) {
        debugPrint('Firestore getLostItems error: $e');
      }
    }
    return List.unmodifiable(_mockLostItems);
  }

  Future<LostItemModel> createLostItem(LostItemModel item) async {
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore
          .collection('lostItems')
          .doc(newItem.id)
          .set(newItem.toMap());
    }

    _mockLostItems.insert(0, newItem);
    return newItem;
  }

  Future<void> updateLostItemStatus(String itemId, String status) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore.collection('lostItems').doc(itemId).update({
          'status': status,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('Update Lost Item error: $e');
      }
    }

    final index = _mockLostItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _mockLostItems[index] = _mockLostItems[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteLostItem(String itemId) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore.collection('lostItems').doc(itemId).delete();
      } catch (e) {
        debugPrint('Delete Lost Item error: $e');
      }
    }
    _mockLostItems.removeWhere((i) => i.id == itemId);
  }

  // ---------------------------------------------------------------------------
  // FOUND ITEMS OPERATIONS
  // ---------------------------------------------------------------------------

  Future<List<FoundItemModel>> getFoundItems() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('foundItems')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((doc) => FoundItemModel.fromMap(doc.data(), doc.id)).toList();
      } catch (e) {
        debugPrint('Firestore getFoundItems error: $e');
      }
    }
    return List.unmodifiable(_mockFoundItems);
  }

  Future<FoundItemModel> createFoundItem(FoundItemModel item) async {
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('foundItems')
            .doc(newItem.id)
            .set(newItem.toMap());
      } catch (e) {
        debugPrint('Create Found Item error: $e');
      }
    }

    _mockFoundItems.insert(0, newItem);
    return newItem;
  }

  Future<void> updateFoundItemStatus(String itemId, String status) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore.collection('foundItems').doc(itemId).update({
          'status': status,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('Update Found Item error: $e');
      }
    }

    final index = _mockFoundItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _mockFoundItems[index] = _mockFoundItems[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteFoundItem(String itemId) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore.collection('foundItems').doc(itemId).delete();
      } catch (e) {
        debugPrint('Delete Found Item error: $e');
      }
    }
    _mockFoundItems.removeWhere((i) => i.id == itemId);
  }

  // ---------------------------------------------------------------------------
  // CLAIMS OPERATIONS
  // ---------------------------------------------------------------------------

  Future<ClaimModel> createClaim(ClaimModel claim) async {
    final newClaim = claim.copyWith(
      id: claim.id.isEmpty ? _uuid.v4() : claim.id,
      status: 'PENDING',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('claims')
            .doc(newClaim.id)
            .set(newClaim.toMap());
      } catch (e) {
        debugPrint('Create Claim error: $e');
      }
    }

    _mockClaims.insert(0, newClaim);

    // Create automated in-app notification for admin/owner
    await createNotification(
      NotificationModel(
        id: _uuid.v4(),
        userId: 'admin',
        title: 'New Item Claim Submitted',
        body: 'A claim was submitted for item ID: ${newClaim.foundItemId}',
        type: 'CLAIM_SUBMITTED',
        targetId: newClaim.id,
        createdAt: DateTime.now(),
      ),
    );

    return newClaim;
  }

  Future<List<ClaimModel>> getClaims() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('claims')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((doc) => ClaimModel.fromMap(doc.data(), doc.id)).toList();
      } catch (e) {
        debugPrint('Get Claims error: $e');
      }
    }
    return List.unmodifiable(_mockClaims);
  }

  Future<void> updateClaimStatus(String claimId, String newStatus) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore.collection('claims').doc(claimId).update({
          'status': newStatus,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('Update Claim Status error: $e');
      }
    }

    final index = _mockClaims.indexWhere((c) => c.id == claimId);
    if (index != -1) {
      final updated = _mockClaims[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _mockClaims[index] = updated;

      // Update associated lost and found items status if approved
      if (newStatus == 'APPROVED') {
        if (updated.lostItemId.isNotEmpty) {
          await updateLostItemStatus(updated.lostItemId, 'CLAIMED');
        }
        if (updated.foundItemId.isNotEmpty) {
          await updateFoundItemStatus(updated.foundItemId, 'CLAIMED');
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CHAT & NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    return _mockChatRooms;
  }

  Future<List<ChatMessageModel>> getMessages(String chatId) async {
    return _mockMessages.where((m) => m.chatId == chatId).toList();
  }

  Future<void> sendMessage(ChatMessageModel message) async {
    _mockMessages.add(message);
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    return _mockNotifications.where((n) => n.userId == userId || n.userId == 'all' || n.userId == 'admin').toList();
  }

  Future<void> createNotification(NotificationModel notification) async {
    _mockNotifications.insert(0, notification);
  }

  Future<List<UserModel>> getAllUsers() async {
    return _mockUsers;
  }

  // ---------------------------------------------------------------------------
  // INITIAL DEMO ACADEMIC SEED DATA
  // ---------------------------------------------------------------------------

  void _seedInitialData() {
    final now = DateTime.now();

    // Default Demo Users
    final admin = UserModel(
      uid: 'admin_101',
      name: 'Dr. Rajesh Sharma',
      email: 'admin@reclaim.edu',
      phone: '+91 9876543210',
      department: 'Administration',
      rollNumber: 'STAFF-001',
      role: 'Admin',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    final student = UserModel(
      uid: 'user_101',
      name: 'Ananya Verma',
      email: 'ananya@reclaim.edu',
      phone: '+91 9123456789',
      department: 'Computer Science & Applications',
      rollNumber: 'MCA-2026-042',
      role: 'Student',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now,
    );

    _mockUsers.addAll([admin, student]);
    if (!FirebaseService.isInitialized) {
      _currentUser = student;
    }

    // Default Seed Lost Items
    _mockLostItems.addAll([
      LostItemModel(
        id: 'lost_01',
        ownerId: student.uid,
        itemName: 'Black Leather Wallet',
        category: 'Wallet',
        description: 'Black WildHorn leather wallet containing College ID card and metro pass.',
        brand: 'WildHorn',
        colour: 'Black',
        dateLost: now.subtract(const Duration(days: 2)),
        locationLost: 'Central Library 2nd Floor Study Hall',
        approximateValue: '₹1,500',
        imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=600&q=80',
        status: 'ACTIVE',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      LostItemModel(
        id: 'lost_02',
        ownerId: student.uid,
        itemName: 'Casio Scientific Calculator FX-991EX',
        category: 'Calculator',
        description: 'Black solar scientific calculator with name label "Ananya" on the back cover.',
        brand: 'Casio',
        colour: 'Black',
        dateLost: now.subtract(const Duration(days: 4)),
        locationLost: 'Block B Computer Lab 3',
        approximateValue: '₹1,800',
        imageUrl: 'https://images.unsplash.com/photo-1594980596870-8aa52a78d8cd?auto=format&fit=crop&w=600&q=80',
        status: 'ACTIVE',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ]);

    // Default Seed Found Items
    _mockFoundItems.addAll([
      FoundItemModel(
        id: 'found_01',
        finderId: admin.uid,
        itemName: 'Black Leather Wallet',
        category: 'Wallet',
        description: 'Found black leather wallet near Library study table. Kept securely at security desk.',
        brand: 'WildHorn',
        colour: 'Black',
        dateFound: now.subtract(const Duration(days: 1)),
        locationFound: 'Central Library Reading Hall',
        imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=600&q=80',
        currentHolder: 'Security Guard Office',
        securityOfficeSubmitted: true,
        status: 'ACTIVE',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      FoundItemModel(
        id: 'found_02',
        finderId: admin.uid,
        itemName: 'Dell Wireless Mouse',
        category: 'Electronics',
        description: 'Black Dell optical wireless USB mouse found on desk 14.',
        brand: 'Dell',
        colour: 'Black',
        dateFound: now.subtract(const Duration(days: 3)),
        locationFound: 'Block B Lab 2',
        imageUrl: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=600&q=80',
        currentHolder: 'Lab Assistant Office',
        securityOfficeSubmitted: false,
        status: 'ACTIVE',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    // Seed Sample Claims & Notifications
    _mockClaims.add(
      ClaimModel(
        id: 'claim_01',
        itemId: 'found_01',
        lostItemId: 'lost_01',
        foundItemId: 'found_01',
        claimantId: student.uid,
        verificationAnswer: 'College ID card inside has Roll No MCA-2026-042 and ₹500 note.',
        uniqueMarks: 'Small scratch on right bottom edge of wallet.',
        contentsInside: 'College ID card, Metro Card, ₹500 cash.',
        status: 'PENDING',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    );

    _mockNotifications.add(
      NotificationModel(
        id: 'notif_01',
        userId: student.uid,
        title: 'Potential Item Match Found! (92%)',
        body: 'A Found item "Black Leather Wallet" matches your lost item report.',
        type: 'POTENTIAL_MATCH',
        targetId: 'found_01',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    );
  }
}
