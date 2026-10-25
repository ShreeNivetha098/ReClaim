import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/models/activity_log_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/reclaim_repository.dart';
import '../../../core/constants/app_constants.dart';

/// Repository for admin-specific Firestore operations.
/// Reuses [FirebaseService] for Firestore/Auth access.
/// Does NOT modify any existing mobile workflows.
class AdminRepository {
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // USER MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Fetches ALL users from Firestore (admin-only operation).
  Future<List<UserModel>> getAllUsers() async {
    if (!FirebaseService.isInitialized) return [];
    try {
      final snap = await FirebaseService.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('AdminRepository.getAllUsers error: $e');
      return [];
    }
  }

  /// Fetches a single user by UID.
  Future<UserModel?> getUserById(String uid) async {
    if (!FirebaseService.isInitialized) return null;
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('AdminRepository.getUserById error: $e');
    }
    return null;
  }

  /// Updates a user's role (admin-only).
  Future<void> updateUserRole(String uid, String newRole) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await FirebaseService.firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('AdminRepository.updateUserRole error: $e');
      rethrow;
    }
  }

  /// Activates or deactivates a user account (admin-only).
  Future<void> toggleUserActive(String uid, bool isActive) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await FirebaseService.firestore.collection('users').doc(uid).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      await FirebaseService.firestore.collection('active_users').doc(uid).set({
        'uid': uid,
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AdminRepository.toggleUserActive error: $e');
      rethrow;
    }
  }

  final ReClaimRepository _reclaimRepo = ReClaimRepository();

  // ---------------------------------------------------------------------------
  // DASHBOARD STATISTICS
  // ---------------------------------------------------------------------------

  /// Returns aggregate counts for the admin overview dashboard,
  /// sharing the exact same repository calls and status definitions
  /// as the dedicated Admin pages.
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final users = await _reclaimRepo.getAllUsers();
      final lostItems = await _reclaimRepo.getLostItems();
      final foundItems = await _reclaimRepo.getFoundItems();
      final claims = await _reclaimRepo.getClaims();

      final activeUsers = users.where((u) => u.isActive).length;

      final activeLost = lostItems
          .where((i) => i.status.toUpperCase() == AppConstants.statusActive)
          .length;
      final activeFound = foundItems
          .where((i) => i.status.toUpperCase() == AppConstants.statusActive)
          .length;

      final unclaimedLost = lostItems
          .where((i) => i.status.toUpperCase() == AppConstants.statusUnclaimed)
          .length;
      final unclaimedFound = foundItems
          .where((i) => i.status.toUpperCase() == AppConstants.statusUnclaimed)
          .length;

      int pending = 0, approved = 0, rejected = 0;
      final pairedClaimedLostIds = <String>{};
      for (final claim in claims) {
        final status = claim.status.toUpperCase();
        if (status == 'PENDING') pending++;
        if (status == 'APPROVED') {
          approved++;
          if (claim.lostItemId.isNotEmpty) {
            pairedClaimedLostIds.add(claim.lostItemId);
          }
        }
        if (status == 'REJECTED') rejected++;
      }

      int claimedLost = 0;
      for (final item in lostItems) {
        if (item.status.toUpperCase() == AppConstants.statusClaimed) {
          if (!pairedClaimedLostIds.contains(item.id)) {
            claimedLost++;
          }
        }
      }

      int claimedFound = 0;
      for (final item in foundItems) {
        if (item.status.toUpperCase() == AppConstants.statusClaimed) {
          claimedFound++;
        }
      }

      return {
        'totalUsers': users.length,
        'activeUsers': activeUsers,
        'totalLostItems': lostItems.length,
        'totalFoundItems': foundItems.length,
        'activeLostItems': activeLost,
        'activeFoundItems': activeFound,
        'pendingClaims': pending,
        'approvedClaims': approved,
        'rejectedClaims': rejected,
        'unclaimedItems': unclaimedLost + unclaimedFound,
        'claimedItems': claimedLost + claimedFound,
      };
    } catch (e) {
      debugPrint('AdminRepository.getDashboardStats error: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY LOGS
  // ---------------------------------------------------------------------------

  /// Logs an admin action to the `activityLogs` collection.
  Future<void> logActivity({
    required String actorId,
    required String actorName,
    required String action,
    required String targetType,
    required String targetId,
    String details = '',
  }) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final logId = _uuid.v4();
      final log = ActivityLogModel(
        id: logId,
        actorId: actorId,
        actorName: actorName,
        action: action,
        targetType: targetType,
        targetId: targetId,
        details: details,
        timestamp: DateTime.now(),
      );
      await FirebaseService.firestore
          .collection('activityLogs')
          .doc(logId)
          .set(log.toMap());
    } catch (e) {
      debugPrint('AdminRepository.logActivity error: $e');
    }
  }

  /// Fetches activity logs ordered by most recent, with optional limit.
  Future<List<ActivityLogModel>> getActivityLogs({int limit = 100}) async {
    if (!FirebaseService.isInitialized) return [];
    try {
      final snap = await FirebaseService.firestore
          .collection('activityLogs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('AdminRepository.getActivityLogs error: $e');
      return [];
    }
  }
}
