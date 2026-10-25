import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclaim/core/routes/app_router.dart';
import 'package:reclaim/core/routes/app_routes.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:reclaim/features/admin/presentation/pages/admin_users_page.dart';
import 'package:reclaim/features/admin/providers/admin_providers.dart';
import 'package:reclaim/shared/models/user_model.dart';

class MockAdminUsersNotifier extends StateNotifier<AsyncValue<List<UserModel>>>
    implements AdminUsersNotifier {
  MockAdminUsersNotifier(List<UserModel> users) : super(AsyncValue.data(users));

  @override
  Future<void> loadUsers() async {}

  @override
  Future<void> updateUserRole(String uid, String role) async {}

  @override
  Future<void> toggleUserActive(String uid, bool isActive) async {}
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

  testWidgets('Fix 1: /admin/lost-reports opens Lost tab and /admin/found-reports opens Found tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 1));

    // 1. Navigate directly to /admin/lost-reports
    appRouter.go(AppRoutes.adminLostReports);
    await tester.pumpAndSettle();

    // Verify AdminReportsPage is active with TabBar at index 0 (Lost Items)
    final reportsFinder = find.byType(AdminReportsPage);
    expect(reportsFinder, findsOneWidget);
    final TabBar lostTabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(lostTabBar.controller?.index, 0);

    // 2. Navigate directly to /admin/found-reports
    appRouter.go(AppRoutes.adminFoundReports);
    await tester.pumpAndSettle();

    // Verify TabBar is at index 1 (Found Items)
    final TabBar foundTabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(foundTabBar.controller?.index, 1);
  });

  testWidgets('Fix 2: Admin Overview stat cards navigate to expected routes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 1));

    // Go to overview
    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();

    // Test Total Users card click
    final totalUsersCard = find.text('Total Users');
    expect(totalUsersCard, findsOneWidget);
    await tester.tap(totalUsersCard);
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminUsers);

    // Return to overview and test Lost Reports card click
    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();
    final lostReportsCard = find.text('Lost Reports');
    expect(lostReportsCard, findsOneWidget);
    await tester.tap(lostReportsCard);
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminLostReports);

    // Return to overview and test Found Reports card click
    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();
    final foundReportsCard = find.text('Found Reports');
    expect(foundReportsCard, findsOneWidget);
    await tester.tap(foundReportsCard);
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminFoundReports);

    // Return to overview and test Claimed Items card click
    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();
    final claimedCard = find.text('Claimed Items');
    expect(claimedCard, findsOneWidget);
    await tester.tap(claimedCard);
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminClaimed);

    // Return to overview and test Unclaimed Items card click
    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();
    final unclaimedCard = find.text('Unclaimed Items');
    expect(unclaimedCard, findsOneWidget);
    await tester.tap(unclaimedCard);
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminUnclaimed);
  });

  testWidgets('Fix 3: Admin cannot deactivate or change role of their own account, but can manage others', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final regularStudent = UserModel(
      uid: 'student_202',
      name: 'Rohan Sharma',
      email: 'rohan@reclaim.edu',
      phone: '9876543299',
      department: 'CSE',
      rollNumber: 'CSE-045',
      role: 'Student',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    await tester.pumpWidget(buildApp([
      adminUsersProvider.overrideWith(
        (ref) => MockAdminUsersNotifier([currentAdminUser, regularStudent]),
      ),
    ]));
    await tester.pump(const Duration(seconds: 1));

    appRouter.go(AppRoutes.adminUsers);
    await tester.pumpAndSettle();

    expect(find.byType(AdminUsersPage), findsOneWidget);

    // 1. Verify 'You' tag appears next to current admin
    expect(find.text('You'), findsOneWidget);

    // 2. The current admin row has tooltip explaining protection
    final tooltipFinder = find.byWidgetPredicate((widget) =>
      widget is Tooltip && widget.message == 'You cannot modify your own administrator account.'
    );
    expect(tooltipFinder, findsOneWidget);

    // 3. Verify disabled buttons inside the self tooltip
    final disabledButtons = find.descendant(
      of: tooltipFinder,
      matching: find.byWidgetPredicate((widget) => widget is IconButton && widget.onPressed == null),
    );
    expect(disabledButtons, findsNWidgets(2)); // Both Edit Role and Deactivate buttons disabled for self

    // 4. Verify regular student has active action buttons (Edit role & Deactivate)
    final allEnabledIconButtons = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.onPressed != null,
    );
    // There should be active buttons for managing the regular student (and refresh button)
    expect(allEnabledIconButtons, findsWidgets);
  });

  testWidgets('Logout works as expected', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(seconds: 1));

    appRouter.go(AppRoutes.adminOverview);
    await tester.pumpAndSettle();

    final logoutFinder = find.text('Logout');
    expect(logoutFinder, findsOneWidget);
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminLogin);
  });
}
