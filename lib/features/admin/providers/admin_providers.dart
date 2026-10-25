import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/models/activity_log_model.dart';
import '../services/admin_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// ADMIN REPOSITORY PROVIDER
// ---------------------------------------------------------------------------

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// ---------------------------------------------------------------------------
// ADMIN ROLE CHECK
// ---------------------------------------------------------------------------

/// Whether the current user has the Admin role.
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role.toLowerCase() == 'admin';
});

// ---------------------------------------------------------------------------
// ALL USERS (Admin)
// ---------------------------------------------------------------------------

class AdminUsersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final AdminRepository _repo;

  AdminUsersNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _repo.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _repo.updateUserRole(uid, newRole);
    await loadUsers();
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    await _repo.toggleUserActive(uid, isActive);
    await loadUsers();
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<UserModel>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminUsersNotifier(repo);
});

// ---------------------------------------------------------------------------
// DASHBOARD STATISTICS
// ---------------------------------------------------------------------------

final adminDashboardStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final usersAsync = ref.watch(adminUsersProvider);
  final lostAsync = ref.watch(lostItemsProvider);
  final foundAsync = ref.watch(foundItemsProvider);
  final claimsAsync = ref.watch(claimsProvider);

  if ((usersAsync.isLoading && !usersAsync.hasValue) ||
      (lostAsync.isLoading && !lostAsync.hasValue) ||
      (foundAsync.isLoading && !foundAsync.hasValue) ||
      (claimsAsync.isLoading && !claimsAsync.hasValue)) {
    return const AsyncValue.loading();
  }

  if (usersAsync.hasError && !usersAsync.hasValue) {
    return AsyncValue.error(usersAsync.error!, usersAsync.stackTrace!);
  }
  if (lostAsync.hasError && !lostAsync.hasValue) {
    return AsyncValue.error(lostAsync.error!, lostAsync.stackTrace!);
  }
  if (foundAsync.hasError && !foundAsync.hasValue) {
    return AsyncValue.error(foundAsync.error!, foundAsync.stackTrace!);
  }
  if (claimsAsync.hasError && !claimsAsync.hasValue) {
    return AsyncValue.error(claimsAsync.error!, claimsAsync.stackTrace!);
  }

  final users = usersAsync.value ?? [];
  final lostItems = lostAsync.value ?? [];
  final foundItems = foundAsync.value ?? [];
  final claims = claimsAsync.value ?? [];

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

  return AsyncValue.data({
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
  });
});

// ---------------------------------------------------------------------------
// ACTIVITY LOGS
// ---------------------------------------------------------------------------

class ActivityLogsNotifier extends StateNotifier<AsyncValue<List<ActivityLogModel>>> {
  final AdminRepository _repo;

  ActivityLogsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repo.getActivityLogs(limit: 200);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activityLogsProvider =
    StateNotifierProvider<ActivityLogsNotifier, AsyncValue<List<ActivityLogModel>>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return ActivityLogsNotifier(repo);
});
