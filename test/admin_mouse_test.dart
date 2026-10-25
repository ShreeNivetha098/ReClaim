import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclaim/core/routes/app_router.dart';
import 'package:reclaim/core/routes/app_routes.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/shared/models/user_model.dart';

void main() {
  testWidgets('Admin overview mouse interaction test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    ReClaimRepository.currentSharedUser = UserModel(
      uid: 'admin_test_123',
      name: 'Admin Test',
      email: 'admin@psgtech.ac.in',
      phone: '9876543210',
      department: 'CSE',
      rollNumber: 'ADM001',
      role: 'Admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    appRouter.go('/admin/overview');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(100, 100));
    await tester.pump();

    for (double y = 50; y < 600; y += 30) {
      await gesture.moveTo(Offset(100, y));
      await tester.pump();
      await gesture.moveTo(Offset(300, y));
      await tester.pump();
      await gesture.moveTo(Offset(600, y));
      await tester.pump();
    }

    // Test clicking Users nav item
    final usersNav = find.text('Users');
    expect(usersNav, findsOneWidget);
    await tester.tap(usersNav);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify route changed to /admin/users
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminUsers);

    // Test clicking Reports nav item
    final reportsNav = find.text('Reports');
    expect(reportsNav, findsOneWidget);
    await tester.tap(reportsNav);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify route changed to /admin/reports
    expect(appRouter.routeInformationProvider.value.uri.toString(), AppRoutes.adminReports);
  });
}
