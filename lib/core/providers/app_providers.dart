import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reclaim_repository.dart';
import '../services/matching_service.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/lost_item_model.dart';
import '../../shared/models/found_item_model.dart';
import '../../shared/models/claim_model.dart';
import '../../shared/models/match_result_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/chat_message_model.dart';

// Single repository instance provider
final repositoryProvider = Provider<ReClaimRepository>((ref) {
  return ReClaimRepository();
});

// Current Auth User Notifier
class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final ReClaimRepository _repo;

  CurrentUserNotifier(this._repo) : super(_repo.currentUser) {
    _init();
  }

  Future<void> _init() async {
    state = await _repo.checkCurrentUser();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String department,
    required String rollNumber,
    required String role,
  }) async {
    final user = await _repo.registerUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      department: department,
      rollNumber: rollNumber,
      role: role,
    );
    state = user;
  }

  Future<void> login(String email, String password) async {
    state = await _repo.loginUser(email: email, password: password);
  }

  Future<void> logout() async {
    await _repo.logoutUser();
    state = null;
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _repo.updateUserProfile(updatedUser);
    state = updatedUser;
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return CurrentUserNotifier(repo);
});

// Lost Items State
class LostItemsNotifier extends StateNotifier<AsyncValue<List<LostItemModel>>> {
  final ReClaimRepository _repo;

  LostItemsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadLostItems();
  }

  Future<void> loadLostItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getLostItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLostItem(LostItemModel item) async {
    await _repo.createLostItem(item);
    await loadLostItems();
  }

  Future<void> deleteLostItem(String itemId) async {
    await _repo.deleteLostItem(itemId);
    await loadLostItems();
  }

  Future<void> updateLostItem(LostItemModel item) async {
    await _repo.updateLostItem(item);
    await loadLostItems();
  }

  Future<void> markRecovered(String itemId) async {
    await _repo.markLostItemRecovered(itemId);
    await loadLostItems();
  }

  Future<void> deleteOwnLostItem(LostItemModel item) async {
    await _repo.deleteOwnLostItem(item);
    await loadLostItems();
  }
}

final lostItemsProvider = StateNotifierProvider<LostItemsNotifier, AsyncValue<List<LostItemModel>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return LostItemsNotifier(repo);
});

// Found Items State
class FoundItemsNotifier extends StateNotifier<AsyncValue<List<FoundItemModel>>> {
  final ReClaimRepository _repo;

  FoundItemsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadFoundItems();
  }

  Future<void> loadFoundItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getFoundItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFoundItem(FoundItemModel item) async {
    await _repo.createFoundItem(item);
    await loadFoundItems();
  }

  Future<void> deleteFoundItem(String itemId) async {
    await _repo.deleteFoundItem(itemId);
    await loadFoundItems();
  }

  Future<void> updateFoundItem(FoundItemModel item) async {
    await _repo.updateFoundItem(item);
    await loadFoundItems();
  }

  Future<void> markReturned(String itemId) async {
    await _repo.markFoundItemReturned(itemId);
    await loadFoundItems();
  }

  Future<void> deleteOwnFoundItem(FoundItemModel item) async {
    await _repo.deleteOwnFoundItem(item);
    await loadFoundItems();
  }
}

final foundItemsProvider = StateNotifierProvider<FoundItemsNotifier, AsyncValue<List<FoundItemModel>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return FoundItemsNotifier(repo);
});

// ---------------------------------------------------------------------------
// ACTIVE-ONLY DERIVED PROVIDERS (for Home feed)
// These filter the full item lists to show only ACTIVE items.
// CLAIMED and UNCLAIMED items are excluded from the normal feed.
// ---------------------------------------------------------------------------

final activeLostItemsProvider = Provider<AsyncValue<List<LostItemModel>>>((ref) {
  final allItems = ref.watch(lostItemsProvider);
  return allItems.whenData(
    (items) => items
        .where((item) => item.status.toUpperCase() == AppConstants.statusActive)
        .toList(),
  );
});

final activeFoundItemsProvider = Provider<AsyncValue<List<FoundItemModel>>>((ref) {
  final allItems = ref.watch(foundItemsProvider);
  return allItems.whenData(
    (items) => items
        .where((item) => item.status.toUpperCase() == AppConstants.statusActive)
        .toList(),
  );
});

// Claims State
class ClaimsNotifier extends StateNotifier<AsyncValue<List<ClaimModel>>> {
  final ReClaimRepository _repo;

  ClaimsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadClaims();
  }

  Future<void> loadClaims() async {
    state = const AsyncValue.loading();
    try {
      final claims = await _repo.getClaims();
      state = AsyncValue.data(claims);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitClaim(ClaimModel claim) async {
    await _repo.createClaim(claim);
    await loadClaims();
  }

  Future<void> updateClaimStatus(String claimId, String status) async {
    await _repo.updateClaimStatus(claimId, status);
    await loadClaims();
  }
}

final claimsProvider = StateNotifierProvider<ClaimsNotifier, AsyncValue<List<ClaimModel>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return ClaimsNotifier(repo);
});

// Notifications Provider (Real-time Stream)
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.getNotificationsStream(user?.uid ?? 'guest');
});

// Unread Notifications Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  return notifsAsync.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// Smart Matches Provider for a given Lost Item
final potentialMatchesProvider = Provider.family<List<MatchResultModel>, LostItemModel>((ref, lostItem) {
  final foundItemsAsync = ref.watch(foundItemsProvider);
  return foundItemsAsync.when(
    data: (foundItems) => MatchingService.findMatchesForLostItem(
      lostItem: lostItem,
      foundItems: foundItems,
      minThreshold: MatchingService.displayThreshold,
    ),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Search & Filter Providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String>((ref) => 'All');
final locationFilterProvider = StateProvider<String>((ref) => 'All');
final statusFilterProvider = StateProvider<String>((ref) => 'All');
final sortOrderProvider = StateProvider<String>((ref) => 'Newest');

// Chat Providers
final chatRoomsProvider = FutureProvider<List<ChatRoomModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.getChatRooms(user?.uid ?? '');
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessageModel>, String>((ref, chatId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getMessages(chatId);
});
