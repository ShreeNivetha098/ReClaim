import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclaim/core/routes/app_router.dart';
import 'package:reclaim/core/routes/app_routes.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/features/admin/presentation/pages/admin_unclaimed_page.dart';
import 'package:reclaim/shared/models/user_model.dart';
import 'package:reclaim/shared/models/lost_item_model.dart';
import 'package:reclaim/shared/models/found_item_model.dart';
import 'package:reclaim/core/providers/app_providers.dart';

class MockLostItemsNotifier extends StateNotifier<AsyncValue<List<LostItemModel>>>
    implements LostItemsNotifier {
  MockLostItemsNotifier(List<LostItemModel> items) : super(AsyncValue.data(items));

  @override
  Future<void> loadLostItems() async {}

  @override
  Future<void> addLostItem(LostItemModel item) async {}

  @override
  Future<void> deleteLostItem(String itemId) async {}

  @override
  Future<void> updateLostItem(LostItemModel item) async {}

  @override
  Future<void> markRecovered(String itemId) async {}

  @override
  Future<void> deleteOwnLostItem(LostItemModel item) async {}
}

class MockFoundItemsNotifier extends StateNotifier<AsyncValue<List<FoundItemModel>>>
    implements FoundItemsNotifier {
  MockFoundItemsNotifier(List<FoundItemModel> items) : super(AsyncValue.data(items));

  @override
  Future<void> loadFoundItems() async {}

  @override
  Future<void> addFoundItem(FoundItemModel item) async {}

  @override
  Future<void> deleteFoundItem(String itemId) async {}

  @override
  Future<void> updateFoundItem(FoundItemModel item) async {}

  @override
  Future<void> markReturned(String itemId) async {}

  @override
  Future<void> deleteOwnFoundItem(FoundItemModel item) async {}
}

void main() {
  final currentAdminUser = UserModel(
    uid: 'admin_101',
    name: 'Dr. Rajesh Sharma',
    email: 'admin@reclaim.edu',
    phone: '9876543210',
    department: 'Administration',
    rollNumber: 'STAFF-001',
    role: 'Admin',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  final unclaimedLostItem = LostItemModel(
    id: 'lost_unclaimed_01',
    ownerId: 'user_1',
    reporterName: 'John Doe',
    reporterEmail: 'john@example.com',
    itemName: 'Unclaimed Lost Laptop',
    category: 'Electronics',
    description: 'Black laptop left behind',
    brand: 'Dell',
    colour: 'Black',
    dateLost: DateTime.now().subtract(const Duration(days: 35)),
    locationLost: 'Library Floor 1',
    approximateValue: '₹50,000',
    status: 'UNCLAIMED',
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 35)),
  );

  final activeLostItem = LostItemModel(
    id: 'lost_active_01',
    ownerId: 'user_2',
    reporterName: 'Alice Smith',
    reporterEmail: 'alice@example.com',
    itemName: 'Active Lost Watch',
    category: 'Electronics',
    description: 'Silver watch',
    brand: 'Fossil',
    colour: 'Silver',
    dateLost: DateTime.now().subtract(const Duration(days: 2)),
    locationLost: 'Cafeteria',
    approximateValue: '₹5,000',
    status: 'ACTIVE',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  final unclaimedFoundItem = FoundItemModel(
    id: 'found_unclaimed_01',
    finderId: 'user_3',
    reporterName: 'Bob Builder',
    reporterEmail: 'bob@example.com',
    itemName: 'Unclaimed Found Keys',
    category: 'Keys',
    description: 'Bunch of 3 keys with blue keychain',
    brand: 'Master',
    colour: 'Silver',
    dateFound: DateTime.now().subtract(const Duration(days: 40)),
    locationFound: 'Block C Hall',
    imageUrl: 'https://example.com/image.jpg',
    status: 'UNCLAIMED',
    createdAt: DateTime.now().subtract(const Duration(days: 40)),
    updatedAt: DateTime.now().subtract(const Duration(days: 40)),
  );

  setUp(() {
    ReClaimRepository.currentSharedUser = currentAdminUser;
  });

  Widget buildApp([List<Override> overrides = const []]) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
  }

  testWidgets('AdminUnclaimedPage loads UNCLAIMED items and filters non-unclaimed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp([
      lostItemsProvider.overrideWith(
        (ref) => MockLostItemsNotifier([unclaimedLostItem, activeLostItem]),
      ),
      foundItemsProvider.overrideWith(
        (ref) => MockFoundItemsNotifier([unclaimedFoundItem]),
      ),
    ]));
    await tester.pump(const Duration(seconds: 1));

    appRouter.go(AppRoutes.adminUnclaimed);
    await tester.pumpAndSettle();

    expect(find.byType(AdminUnclaimedPage), findsOneWidget);
    expect(find.text('Unclaimed Items'), findsNWidgets(2)); // AppBar title + Page title

    // Verify Lost Items tab shows unclaimed items and NOT active items
    expect(find.text('Unclaimed Lost Laptop'), findsOneWidget);
    expect(find.text('Active Lost Watch'), findsNothing);
    expect(find.text('John Doe'), findsOneWidget);

    // Verify View Details button is present
    expect(find.text('View Details'), findsWidgets);

    // Switch to Found Items tab
    final foundTab = find.text('  Found Items (1)  ');
    expect(foundTab, findsOneWidget);
    await tester.tap(foundTab);
    await tester.pumpAndSettle();

    // Verify Found tab shows unclaimed found item
    expect(find.text('Unclaimed Found Keys'), findsOneWidget);
    expect(find.text('Bob Builder'), findsOneWidget);
  });
}
