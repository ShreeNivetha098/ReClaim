import 'dart:async';
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
import '../../shared/models/match_result_model.dart';
import 'firebase_service.dart';
import 'id_photo_service.dart';
import 'image_store_service.dart';
import 'matching_service.dart';
import '../constants/app_constants.dart';

/// Thrown when a user reports an item as lost that they already reported as
/// found, or the other way round.
class DuplicateReportException implements Exception {
  final String message;
  const DuplicateReportException(this.message);

  @override
  String toString() => message;
}

class ReClaimRepository {
  static const _uuid = Uuid();

  // In-Memory state fallback when live Firebase configuration is pending
  final List<UserModel> _mockUsers = [];
  final List<LostItemModel> _mockLostItems = [];
  final List<FoundItemModel> _mockFoundItems = [];
  final List<ClaimModel> _mockClaims = [];
  final List<ChatRoomModel> _mockChatRooms = [];
  final List<ChatMessageModel> _mockMessages = [];
  final List<NotificationModel> _mockNotifications = [];
  final StreamController<List<NotificationModel>> _mockNotifController =
      StreamController<List<NotificationModel>>.broadcast();

  static UserModel? currentSharedUser;

  UserModel? _currentUser;
  set currentUser(UserModel? u) {
    _currentUser = u;
    currentSharedUser = u;
  }

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
            currentUser = user;
            _syncActiveUser(user);
            return user;
          }
        } catch (e) {
          debugPrint('Error fetching current user profile: $e');
        }
      }
      currentUser = null;
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
      currentUser = newUser;
      _syncActiveUser(newUser);
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
    currentUser = newUser;
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
      debugPrint('ReClaimRepository.loginUser: auth UID=${credential.user!.uid}');
      debugPrint('ReClaimRepository.loginUser: Firestore path=users/${credential.user!.uid}, exists=${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint('ReClaimRepository.loginUser: raw data role="${data['role']}"');
        debugPrint('ReClaimRepository.loginUser: raw data Role="${data['Role']}"');
        final user = UserModel.fromMap(data, doc.id);
        debugPrint('ReClaimRepository.loginUser: parsed UserModel role="${user.role}"');
        currentUser = user;
        _syncActiveUser(user);
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

    currentUser = found;
    return found;
  }

  Future<void> logoutUser() async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.auth.signOut();
    }
    currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.auth.sendPasswordResetEmail(email: email);
    }
  }

  /// Fields only the verification flow may change, never a profile edit.
  static const _verificationFields = {'verificationStatus', 'verifiedBy', 'verifiedAt', 'verificationNote'};

  Future<void> updateUserProfile(UserModel updatedUser) async {
    currentUser = updatedUser;
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('users')
            .doc(updatedUser.uid)
            .update(updatedUser.toMap()..removeWhere((key, _) => _verificationFields.contains(key)));
        _syncActiveUser(updatedUser);
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
  // COLLEGE ID VERIFICATION
  // ---------------------------------------------------------------------------

  /// Uploads the signed-in user's college ID photo and asks an admin to review it.
  Future<UserModel> submitIdPhoto(Uint8List bytes) async {
    final user = _requireCurrentUser();
    await IdPhotoService.save(user.uid, bytes);
    final updated = user.withVerification(status: AppConstants.verificationPending);
    await _writeOwnVerification(updated);
    return updated;
  }

  /// Withdraws a photo that is still waiting for review.
  Future<UserModel> withdrawIdPhoto() async {
    final user = _requireCurrentUser();
    await IdPhotoService.delete(user.uid);
    final updated = user.withVerification(status: AppConstants.verificationNone);
    await _writeOwnVerification(updated);
    return updated;
  }

  UserModel _requireCurrentUser() {
    final user = currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user;
  }

  Future<void> _writeOwnVerification(UserModel updated) async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore.collection('users').doc(updated.uid).update({
        'verificationStatus': updated.verificationStatus,
        'verificationNote': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    _replaceMockUser(updated);
    currentUser = updated;
  }

  void _replaceMockUser(UserModel user) {
    final index = _mockUsers.indexWhere((u) => u.uid == user.uid);
    if (index != -1) _mockUsers[index] = user;
  }

  /// Admin decision on a user's college ID. The user's status and the photo's
  /// deletion are written in one batch, so the photo never outlives the review.
  Future<void> reviewIdVerification({
    required UserModel user,
    required bool approve,
    required String adminName,
    String? note,
  }) async {
    final now = DateTime.now();
    final updated = approve
        ? user.withVerification(
            status: AppConstants.verificationVerified,
            verifiedBy: adminName,
            verifiedAt: now,
          )
        : user.withVerification(status: AppConstants.verificationRejected, note: note);

    if (FirebaseService.isInitialized) {
      final firestore = FirebaseService.firestore;
      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(user.uid), {
        'verificationStatus': updated.verificationStatus,
        'verifiedBy': updated.verifiedBy,
        'verifiedAt': approve ? Timestamp.fromDate(now) : null,
        'verificationNote': updated.verificationNote,
        'updatedAt': Timestamp.fromDate(now),
      });
      batch.delete(firestore.collection(IdPhotoService.collection).doc(user.uid));
      await batch.commit();
    } else {
      await IdPhotoService.delete(user.uid);
    }
    _replaceMockUser(updated);

    await createNotification(
      NotificationModel(
        id: _uuid.v4(),
        userId: user.uid,
        title: approve ? 'Your account is verified' : 'ID verification not approved',
        body: approve
            ? 'An admin checked your college ID. Your photo has been deleted.'
            : '${note == null || note.trim().isEmpty ? 'Your photo could not be verified.' : note.trim()} '
                'Your photo has been deleted; you can upload a clearer one from your profile.',
        type: approve ? 'VERIFICATION_APPROVED' : 'VERIFICATION_REJECTED',
        targetId: user.uid,
        createdAt: now,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE UPLOAD
  // ---------------------------------------------------------------------------

  /// Saves a photo in Firestore and returns the reference for `imageUrl`.
  Future<String?> uploadImageBytes(Uint8List bytes) async {
    if (FirebaseService.isInitialized) {
      return ImageStoreService.save(bytes, uploaderId: _currentUser?.uid ?? '');
    }
    // Fallback for local mock testing when Firebase is not initialized
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
        final items = snap.docs.map((doc) => LostItemModel.fromMap(doc.data(), doc.id)).toList();
        return _autoClassifyLostItems(items);
      } catch (e) {
        debugPrint('Firestore getLostItems error: $e');
      }
    }
    _autoClassifyMockLostItems();
    return List.unmodifiable(_mockLostItems);
  }

  Future<LostItemModel> createLostItem(LostItemModel item) async {
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _rejectIfOwnFoundReport(newItem);

    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore
          .collection('lostItems')
          .doc(newItem.id)
          .set(newItem.toMap());
    }

    _mockLostItems.insert(0, newItem);

    // Common notification dispatch after successful report creation
    try {
      await _dispatchCommonNotification(
        title: 'New Lost Item Reported',
        body: _buildNotificationMessage(
          itemName: newItem.itemName,
          colour: newItem.colour,
          location: newItem.locationLost,
          isLost: true,
        ),
        itemId: newItem.id,
        itemType: 'LOST',
        reporterId: newItem.ownerId,
      );
    } catch (notificationError) {
      debugPrint('Notification creation failed for lost item ${newItem.id}: $notificationError');
    }

    try {
      await _notifyMatchesForLostItem(newItem);
    } catch (e) {
      debugPrint('Match notification failed for lost item ${newItem.id}: $e');
    }

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
        final items = snap.docs.map((doc) => FoundItemModel.fromMap(doc.data(), doc.id)).toList();
        return _autoClassifyFoundItems(items);
      } catch (e) {
        debugPrint('Firestore getFoundItems error: $e');
      }
    }
    _autoClassifyMockFoundItems();
    return List.unmodifiable(_mockFoundItems);
  }

  Future<FoundItemModel?> getFoundItemById(String itemId) async {
    if (FirebaseService.isInitialized) {
      try {
        final doc = await FirebaseService.firestore.collection('foundItems').doc(itemId).get();
        if (doc.exists && doc.data() != null) {
          return FoundItemModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Firestore getFoundItemById error: $e');
      }
    }
    for (final item in _mockFoundItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  Future<FoundItemModel> createFoundItem(FoundItemModel item) async {
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _rejectIfOwnLostReport(newItem);

    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore
          .collection('foundItems')
          .doc(newItem.id)
          .set(newItem.toMap());
    }

    _mockFoundItems.insert(0, newItem);

    // Common notification dispatch after successful report creation
    try {
      await _dispatchCommonNotification(
        title: 'New Found Item Reported',
        body: _buildNotificationMessage(
          itemName: newItem.itemName,
          colour: newItem.colour,
          location: newItem.locationFound,
          isLost: false,
        ),
        itemId: newItem.id,
        itemType: 'FOUND',
        reporterId: newItem.finderId,
      );
    } catch (notificationError) {
      debugPrint('Notification creation failed for found item ${newItem.id}: $notificationError');
    }

    try {
      await _notifyMatchesForFoundItem(newItem);
    } catch (e) {
      debugPrint('Match notification failed for found item ${newItem.id}: $e');
    }

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
  // OWNER ACTIONS (edit, mark as recovered, delete own reports)
  // Unlike the admin helpers above, these let errors reach the caller so a
  // screen never reports success for a write the security rules refused.
  // ---------------------------------------------------------------------------

  /// Fields an owner's edit must never overwrite.
  static const _ownerProtectedFields = {'id', 'ownerId', 'finderId', 'status', 'createdAt'};

  Future<void> updateLostItem(LostItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _rejectIfOwnFoundReport(updated);
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore
          .collection('lostItems')
          .doc(item.id)
          .update(updated.toMap()..removeWhere((key, _) => _ownerProtectedFields.contains(key)));
    }
    final index = _mockLostItems.indexWhere((i) => i.id == item.id);
    if (index != -1) _mockLostItems[index] = updated;

    // New details may match found items that did not match before.
    try {
      await _notifyMatchesForLostItem(updated);
    } catch (e) {
      debugPrint('Match notification failed for edited lost item ${item.id}: $e');
    }
  }

  Future<void> updateFoundItem(FoundItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _rejectIfOwnLostReport(updated);
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore
          .collection('foundItems')
          .doc(item.id)
          .update(updated.toMap()..removeWhere((key, _) => _ownerProtectedFields.contains(key)));
    }
    final index = _mockFoundItems.indexWhere((i) => i.id == item.id);
    if (index != -1) _mockFoundItems[index] = updated;

    try {
      await _notifyMatchesForFoundItem(updated);
    } catch (e) {
      debugPrint('Match notification failed for edited found item ${item.id}: $e');
    }
  }

  /// The owner got their item back, so the lost report is closed.
  Future<void> markLostItemRecovered(String itemId) async {
    final now = DateTime.now();
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore.collection('lostItems').doc(itemId).update({
        'status': AppConstants.statusReturned,
        'updatedAt': Timestamp.fromDate(now),
      });
    }
    final index = _mockLostItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _mockLostItems[index] =
          _mockLostItems[index].copyWith(status: AppConstants.statusReturned, updatedAt: now);
    }
  }

  /// The finder handed the item back, so the found report is closed.
  Future<void> markFoundItemReturned(String itemId) async {
    final now = DateTime.now();
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore.collection('foundItems').doc(itemId).update({
        'status': AppConstants.statusReturned,
        'updatedAt': Timestamp.fromDate(now),
      });
    }
    final index = _mockFoundItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _mockFoundItems[index] =
          _mockFoundItems[index].copyWith(status: AppConstants.statusReturned, updatedAt: now);
    }
  }

  Future<void> deleteOwnLostItem(LostItemModel item) async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore.collection('lostItems').doc(item.id).delete();
    }
    await ImageStoreService.delete(item.imageUrl);
    _mockLostItems.removeWhere((i) => i.id == item.id);
  }

  Future<void> deleteOwnFoundItem(FoundItemModel item) async {
    if (FirebaseService.isInitialized) {
      await FirebaseService.firestore.collection('foundItems').doc(item.id).delete();
    }
    await ImageStoreService.delete(item.imageUrl);
    _mockFoundItems.removeWhere((i) => i.id == item.id);
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
  final normalizedStatus = newStatus.toUpperCase();
  final now = DateTime.now();

  if (FirebaseService.isInitialized) {
    // Read the actual claim from Firestore. Do not depend on _mockClaims.
    final claimRef =
        FirebaseService.firestore.collection('claims').doc(claimId);

    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists || claimSnapshot.data() == null) {
      throw StateError('Claim not found: $claimId');
    }

    final claim = ClaimModel.fromMap(
      claimSnapshot.data()!,
      claimSnapshot.id,
    );

    // Update the claim and linked item records together.
    // If any write fails, Firestore will not partially apply the batch.
    final batch = FirebaseService.firestore.batch();

    batch.update(claimRef, {
      'status': normalizedStatus,
      'updatedAt': Timestamp.fromDate(now),
    });

    if (normalizedStatus == 'APPROVED') {
      if (claim.lostItemId.isNotEmpty) {
        final lostItemRef = FirebaseService.firestore
            .collection('lostItems')
            .doc(claim.lostItemId);

        batch.update(lostItemRef, {
          'status': 'CLAIMED',
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      if (claim.foundItemId.isNotEmpty) {
        final foundItemRef = FirebaseService.firestore
            .collection('foundItems')
            .doc(claim.foundItemId);

        batch.update(foundItemRef, {
          'status': 'CLAIMED',
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    }

    // Let errors propagate instead of showing a false success message.
    await batch.commit();

    // Keep the in-memory cache consistent, if this claim is cached.
    final index = _mockClaims.indexWhere((c) => c.id == claimId);
    if (index != -1) {
      _mockClaims[index] = _mockClaims[index].copyWith(
        status: normalizedStatus,
        updatedAt: now,
      );
    }

    await _notifyClaimDecision(claim, normalizedStatus);
    return;
  }

  // Local/mock mode when Firebase is not initialized.
  final index = _mockClaims.indexWhere((c) => c.id == claimId);

  if (index == -1) {
    throw StateError('Claim not found: $claimId');
  }

  final updatedClaim = _mockClaims[index].copyWith(
    status: normalizedStatus,
    updatedAt: now,
  );

  _mockClaims[index] = updatedClaim;

  if (normalizedStatus == 'APPROVED') {
    if (updatedClaim.lostItemId.isNotEmpty) {
      await updateLostItemStatus(updatedClaim.lostItemId, 'CLAIMED');
    }

    if (updatedClaim.foundItemId.isNotEmpty) {
      await updateFoundItemStatus(updatedClaim.foundItemId, 'CLAIMED');
    }
  }

  await _notifyClaimDecision(updatedClaim, normalizedStatus);
}

  /// Tells the claimant whether their claim was approved or rejected.
  /// The decision is already saved, so a failed notification is only logged.
  Future<void> _notifyClaimDecision(ClaimModel claim, String status) async {
    if (status != 'APPROVED' && status != 'REJECTED') return;
    if (claim.claimantId.isEmpty) return;

    try {
      final item = await getFoundItemById(claim.foundItemId);
      final itemName = item?.itemName ?? 'the item';
      final holder = item?.currentHolder.trim() ?? '';
      final approved = status == 'APPROVED';

      await createNotification(
        NotificationModel(
          id: 'claim_${claim.id}_${status.toLowerCase()}',
          userId: claim.claimantId,
          title: approved ? 'Claim approved: $itemName' : 'Claim not approved: $itemName',
          body: approved
              ? 'Your ownership was verified. Collect it from '
                  '${holder.isEmpty ? 'the campus security office' : holder}.'
              : 'The admin could not verify your ownership. Contact the campus '
                  'security office if you think this is a mistake.',
          type: approved ? 'CLAIM_APPROVED' : 'CLAIM_REJECTED',
          targetId: claim.foundItemId,
          itemType: 'FOUND',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Claim decision notification failed for ${claim.id}: $e');
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

  void _notifyMockNotificationsChanged() {
    if (!_mockNotifController.isClosed) {
      _mockNotifController.add(List.unmodifiable(_mockNotifications));
    }
  }

  String _buildNotificationMessage({
    required String itemName,
    required String? colour,
    required String location,
    required bool isLost,
  }) {
    final cleanItem = itemName.trim();
    final cleanColour = (colour ?? '').trim();
    final cleanLoc = location.trim();

    String itemPhrase = cleanItem;
    if (cleanColour.isNotEmpty &&
        cleanColour.toLowerCase() != 'n/a' &&
        cleanColour.toLowerCase() != 'unknown') {
      if (!cleanItem.toLowerCase().contains(cleanColour.toLowerCase())) {
        itemPhrase = '$cleanColour $cleanItem';
      }
    }

    if (isLost) {
      if (cleanLoc.isNotEmpty && cleanLoc.toLowerCase() != 'n/a') {
        return '$itemPhrase was reported near $cleanLoc.';
      } else {
        return '$itemPhrase was reported lost on campus.';
      }
    } else {
      if (cleanLoc.isNotEmpty && cleanLoc.toLowerCase() != 'n/a') {
        return '$itemPhrase was found near $cleanLoc.';
      } else {
        return '$itemPhrase was found on campus.';
      }
    }
  }

  Future<void> _syncActiveUser(UserModel user) async {
    if (FirebaseService.isInitialized && user.uid.isNotEmpty) {
      try {
        await FirebaseService.firestore
            .collection('active_users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'isActive': user.isActive,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('ReClaimRepository._syncActiveUser error: $e');
      }
    }
  }

  Future<List<UserModel>> getActiveUsers() async {
    if (FirebaseService.isInitialized) {
      try {
        final activeSnap = await FirebaseService.firestore
            .collection('active_users')
            .where('isActive', isEqualTo: true)
            .get();
        if (activeSnap.docs.isNotEmpty) {
          return activeSnap.docs.map((doc) {
            final data = doc.data();
            return UserModel(
              uid: doc.id,
              name: '',
              email: '',
              phone: '',
              department: '',
              rollNumber: '',
              role: 'Student',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: data['isActive'] ?? true,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('ReClaimRepository.getActiveUsers (active_users) error: $e');
      }

      // Fallback: Check direct users collection if accessible
      try {
        final snap = await FirebaseService.firestore.collection('users').get();
        return snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .where((u) => u.isActive)
            .toList();
      } catch (e) {
        debugPrint('ReClaimRepository.getActiveUsers (users fallback) error: $e');
      }
    }
    return _mockUsers.where((u) => u.isActive).toList();
  }

  Future<void> _dispatchCommonNotification({
    required String title,
    required String body,
    required String itemId,
    required String itemType,
    required String reporterId,
  }) async {
    final now = DateTime.now();

    if (FirebaseService.isInitialized) {
      try {
        final activeUsers = await getActiveUsers();
        final eligibleRecipients = activeUsers
            .where((u) => u.uid != reporterId && u.uid.isNotEmpty)
            .toList();

        if (eligibleRecipients.isNotEmpty) {
          final batch = FirebaseService.firestore.batch();
          int opsCount = 0;

          for (final recipient in eligibleRecipients) {
            final notifRef = FirebaseService.firestore.collection('notifications').doc();
            final notif = NotificationModel(
              id: notifRef.id,
              userId: recipient.uid,
              title: title,
              body: body,
              type: 'COMMON',
              targetId: itemId,
              itemType: itemType,
              isRead: false,
              createdAt: now,
            );
            batch.set(notifRef, notif.toMap());
            opsCount++;

            if (opsCount >= 400) {
              await batch.commit();
              opsCount = 0;
            }
          }

          if (opsCount > 0) {
            await batch.commit();
          }
        }
      } catch (e) {
        debugPrint('Error dispatching common notifications to Firestore: $e');
      }
    }

    // In-memory mock dispatch for offline mode and tests
    final eligibleMockRecipients = _mockUsers
        .where((u) => u.uid != reporterId && u.isActive)
        .toList();
    for (final recipient in eligibleMockRecipients) {
      _mockNotifications.insert(
        0,
        NotificationModel(
          id: _uuid.v4(),
          userId: recipient.uid,
          title: title,
          body: body,
          type: 'COMMON',
          targetId: itemId,
          itemType: itemType,
          isRead: false,
          createdAt: now,
        ),
      );
    }
    _notifyMockNotificationsChanged();
  }

  // ---------------------------------------------------------------------------
  // SAME-ITEM CHECK
  // One person cannot report the same item as both lost and found.
  // ---------------------------------------------------------------------------

  Future<void> _rejectIfOwnFoundReport(LostItemModel lostItem) async {
    final duplicate = MatchingService.ownFoundReportOfSameItem(
      lostItem: lostItem,
      foundItems: await getFoundItems(),
    );
    if (duplicate != null) {
      throw DuplicateReportException(
        'You have already reported finding "${duplicate.itemName}". '
        'You cannot report the same item as both lost and found.',
      );
    }
  }

  Future<void> _rejectIfOwnLostReport(FoundItemModel foundItem) async {
    final duplicate = MatchingService.ownLostReportOfSameItem(
      foundItem: foundItem,
      lostItems: await getLostItems(),
    );
    if (duplicate != null) {
      throw DuplicateReportException(
        'You have already reported losing "${duplicate.itemName}". '
        'You cannot report the same item as both lost and found.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MATCH NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Notifies the owners of lost reports that strongly match a new found item.
  /// Only the lost report's owner is told, never the finder.
  Future<void> _notifyMatchesForFoundItem(FoundItemModel foundItem) async {
    final matches = MatchingService.findMatchesForFoundItem(
      foundItem: foundItem,
      lostItems: await getLostItems(),
      minThreshold: MatchingService.notifyThreshold,
    );
    for (final match in matches) {
      await _sendMatchNotification(match);
    }
  }

  /// Tells the reporter of a new lost item about found items that already match it.
  Future<void> _notifyMatchesForLostItem(LostItemModel lostItem) async {
    final matches = MatchingService.findMatchesForLostItem(
      lostItem: lostItem,
      foundItems: await getFoundItems(),
      minThreshold: MatchingService.notifyThreshold,
    );
    for (final match in matches) {
      await _sendMatchNotification(match);
    }
  }

  /// Sends one notification per lost/found pair to the lost report's owner.
  /// The document ID is fixed per pair, so a pair is never notified twice:
  /// rewriting an existing notification is refused by the security rules.
  Future<void> _sendMatchNotification(MatchResultModel match) async {
    final lost = match.lostItem;
    final found = match.foundItem;
    final notif = NotificationModel(
      id: 'match_${lost.id}_${found.id}',
      userId: lost.ownerId,
      title: 'Possible match for your ${lost.itemName} '
          '(${match.matchPercentage.toStringAsFixed(0)}%)',
      body: '${_buildNotificationMessage(
        itemName: found.itemName,
        colour: found.colour,
        location: found.locationFound,
        isLost: false,
      )} Tap to check if it is yours.',
      type: 'POTENTIAL_MATCH',
      targetId: found.id,
      itemType: 'FOUND',
      lostItemId: lost.id,
      createdAt: DateTime.now(),
    );

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('notifications')
            .doc(notif.id)
            .set(notif.toMap());
      } catch (e) {
        debugPrint('Match notification ${notif.id} not sent (already sent or denied): $e');
      }
    }

    if (_mockNotifications.every((n) => n.id != notif.id)) {
      _mockNotifications.insert(0, notif);
      _notifyMockNotificationsChanged();
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        final list = snap.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e) {
        debugPrint('ReClaimRepository.getNotifications error: $e');
      }
    }
    final list = _mockNotifications
        .where((n) => n.userId == userId || n.userId == 'all' || n.userId == 'admin')
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) async* {
    if (FirebaseService.isInitialized) {
      yield* FirebaseService.firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
      return;
    }

    final current = _mockNotifications
        .where((n) => n.userId == userId || n.userId == 'all' || n.userId == 'admin')
        .toList();
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield current;

    yield* _mockNotifController.stream.map((list) {
      final filtered = list
          .where((n) => n.userId == userId || n.userId == 'all' || n.userId == 'admin')
          .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  Future<void> createNotification(NotificationModel notification) async {
    final notif = notification.id.isEmpty
        ? notification.copyWith(id: _uuid.v4())
        : notification;

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('notifications')
            .doc(notif.id)
            .set(notif.toMap());
      } catch (e) {
        debugPrint('ReClaimRepository.createNotification error: $e');
      }
    }

    _mockNotifications.insert(0, notif);
    _notifyMockNotificationsChanged();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      } catch (e) {
        debugPrint('ReClaimRepository.markNotificationAsRead error: $e');
      }
    }

    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
      _notifyMockNotificationsChanged();
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        if (snap.docs.isNotEmpty) {
          final batch = FirebaseService.firestore.batch();
          for (final doc in snap.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('ReClaimRepository.markAllNotificationsAsRead error: $e');
      }
    }

    for (int i = 0; i < _mockNotifications.length; i++) {
      if (_mockNotifications[i].userId == userId) {
        _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
      }
    }
    _notifyMockNotificationsChanged();
  }

  Future<List<UserModel>> getAllUsers() async {
    if (FirebaseService.isInitialized) {
      try {
        final snap = await FirebaseService.firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e) {
        debugPrint('ReClaimRepository.getAllUsers error: $e');
      }
    }
    return _mockUsers;
  }

  // ---------------------------------------------------------------------------
  // AUTOMATIC UNCLAIMED CLASSIFICATION
  // ---------------------------------------------------------------------------

  /// Checks if an ACTIVE item's createdAt is older than the configured
  /// unclaimed threshold. Used to auto-classify stale items.
  bool _isExpiredForUnclaimed(DateTime createdAt) {
    final cutoff = DateTime.now().subtract(
      Duration(days: AppConstants.unclaimedAfterDays),
    );
    return createdAt.isBefore(cutoff);
  }

  /// Auto-classifies ACTIVE lost items older than the threshold as UNCLAIMED.
  /// Updates Firestore in a fire-and-forget manner and returns the updated list.
  List<LostItemModel> _autoClassifyLostItems(List<LostItemModel> items) {
    final result = <LostItemModel>[];
    for (final item in items) {
      if (item.status == AppConstants.statusActive &&
          _isExpiredForUnclaimed(item.createdAt)) {
        // Fire-and-forget Firestore update
        updateLostItemStatus(item.id, AppConstants.statusUnclaimed);
        result.add(item.copyWith(status: AppConstants.statusUnclaimed));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  /// Auto-classifies ACTIVE found items older than the threshold as UNCLAIMED.
  /// Updates Firestore in a fire-and-forget manner and returns the updated list.
  List<FoundItemModel> _autoClassifyFoundItems(List<FoundItemModel> items) {
    final result = <FoundItemModel>[];
    for (final item in items) {
      if (item.status == AppConstants.statusActive &&
          _isExpiredForUnclaimed(item.createdAt)) {
        // Fire-and-forget Firestore update
        updateFoundItemStatus(item.id, AppConstants.statusUnclaimed);
        result.add(item.copyWith(status: AppConstants.statusUnclaimed));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  /// Auto-classifies stale ACTIVE mock lost items as UNCLAIMED.
  void _autoClassifyMockLostItems() {
    for (int i = 0; i < _mockLostItems.length; i++) {
      if (_mockLostItems[i].status == AppConstants.statusActive &&
          _isExpiredForUnclaimed(_mockLostItems[i].createdAt)) {
        _mockLostItems[i] = _mockLostItems[i].copyWith(
          status: AppConstants.statusUnclaimed,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  /// Auto-classifies stale ACTIVE mock found items as UNCLAIMED.
  void _autoClassifyMockFoundItems() {
    for (int i = 0; i < _mockFoundItems.length; i++) {
      if (_mockFoundItems[i].status == AppConstants.statusActive &&
          _isExpiredForUnclaimed(_mockFoundItems[i].createdAt)) {
        _mockFoundItems[i] = _mockFoundItems[i].copyWith(
          status: AppConstants.statusUnclaimed,
          updatedAt: DateTime.now(),
        );
      }
    }
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
        reporterName: student.name,
        reporterEmail: student.email,
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
        reporterName: student.name,
        reporterEmail: student.email,
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
        reporterName: admin.name,
        reporterEmail: admin.email,
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
        reporterName: admin.name,
        reporterEmail: admin.email,
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
