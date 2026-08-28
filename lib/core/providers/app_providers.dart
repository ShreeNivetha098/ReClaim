import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reclaim_repository.dart';
import '../services/matching_service.dart';
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
    final user = await _repo.checkCurrentUser();
    state = user;
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
    final user = await _repo.loginUser(email: email, password: password);
    state = user;
  }

  Future<void> logout() async {
    await _repo.logoutUser();
    state = null;
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _repo.updateUserProfile(updatedUser);
    state = updatedUser;
  }

  void switchRoleForDemo(String newRole) {
    if (state != null) {
      final updated = state!.copyWith(role: newRole);
      _repo.updateUserProfile(updated);
      state = updated;
    }
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
}

final foundItemsProvider = StateNotifierProvider<FoundItemsNotifier, AsyncValue<List<FoundItemModel>>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return FoundItemsNotifier(repo);
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

// Notifications Provider
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.getNotifications(user?.uid ?? 'guest');
});

// Smart Matches Provider for a given Lost Item
final potentialMatchesProvider = Provider.family<List<MatchResultModel>, LostItemModel>((ref, lostItem) {
  final foundItemsAsync = ref.watch(foundItemsProvider);
  return foundItemsAsync.when(
    data: (foundItems) => MatchingService.findMatchesForLostItem(
      lostItem: lostItem,
      foundItems: foundItems,
      minThreshold: 35.0,
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
