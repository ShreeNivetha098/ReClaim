import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclaim/core/constants/app_constants.dart';
import 'package:reclaim/core/utils/date_formatter.dart';
import 'package:reclaim/shared/models/lost_item_model.dart';
import 'package:reclaim/shared/widgets/item_card.dart';
import 'package:reclaim/features/item_details/presentation/item_details_screen.dart';

void main() {
  group('Unclaimed Countdown Calculation Tests', () {
    final fixedNow = DateTime(2026, 10, 25, 12, 0, 0);

    test('1. Newly posted report (0 days old) has 30 days remaining', () {
      final newlyPostedDate = fixedNow;
      final days = DateFormatter.daysRemainingUntilUnclaimed(newlyPostedDate, fixedNow);
      expect(days, equals(30));

      final label = DateFormatter.getUnclaimedCountdownLabel(newlyPostedDate, 'ACTIVE', fixedNow);
      expect(label, equals('30 days left'));
    });

    test('2. Report 12 days old has 18 days remaining', () {
      final twelveDaysOld = fixedNow.subtract(const Duration(days: 12));
      final days = DateFormatter.daysRemainingUntilUnclaimed(twelveDaysOld, fixedNow);
      expect(days, equals(18));

      final label = DateFormatter.getUnclaimedCountdownLabel(twelveDaysOld, 'ACTIVE', fixedNow);
      expect(label, equals('18 days left'));
    });

    test('3. Report 29 days old has 1 day remaining', () {
      final twentyNineDaysOld = fixedNow.subtract(const Duration(days: 29));
      final days = DateFormatter.daysRemainingUntilUnclaimed(twentyNineDaysOld, fixedNow);
      expect(days, equals(1));

      final label = DateFormatter.getUnclaimedCountdownLabel(twentyNineDaysOld, 'ACTIVE', fixedNow);
      expect(label, equals('1 day left'));
    });

    test('4. Report at the 30-day boundary has 0 days left and displays expired label', () {
      final boundaryDate = fixedNow.subtract(const Duration(days: AppConstants.unclaimedAfterDays));
      final days = DateFormatter.daysRemainingUntilUnclaimed(boundaryDate, fixedNow);
      expect(days, equals(0));

      final label = DateFormatter.getUnclaimedCountdownLabel(boundaryDate, 'ACTIVE', fixedNow);
      expect(label, equals('Unclaimed period expired'));
      expect(days, isNot(isNegative));
    });

    test('5. Report older than 30 days (e.g. 35 days) never shows negative countdown', () {
      final olderDate = fixedNow.subtract(const Duration(days: 35));
      final days = DateFormatter.daysRemainingUntilUnclaimed(olderDate, fixedNow);
      expect(days, equals(0));
      expect(days, isNot(isNegative));

      final label = DateFormatter.getUnclaimedCountdownLabel(olderDate, 'ACTIVE', fixedNow);
      expect(label, equals('Unclaimed period expired'));
    });

    test('6. Claimed reports (CLAIMED, RETURNED, CLOSED) do not display active countdown', () {
      final activeDate = fixedNow.subtract(const Duration(days: 12));

      // CLAIMED
      final claimedLabel = DateFormatter.getUnclaimedCountdownLabel(activeDate, 'CLAIMED', fixedNow);
      expect(claimedLabel, isNull);

      // RETURNED
      final returnedLabel = DateFormatter.getUnclaimedCountdownLabel(activeDate, 'RETURNED', fixedNow);
      expect(returnedLabel, isNull);

      // CLOSED
      final closedLabel = DateFormatter.getUnclaimedCountdownLabel(activeDate, 'CLOSED', fixedNow);
      expect(closedLabel, isNull);
    });

    test('7. UNCLAIMED reports display Unclaimed period expired', () {
      final date = fixedNow.subtract(const Duration(days: 40));
      final label = DateFormatter.getUnclaimedCountdownLabel(date, 'UNCLAIMED', fixedNow);
      expect(label, equals('Unclaimed period expired'));
    });

    test('8. Model convenience getters calculate countdown correctly', () {
      final item = LostItemModel(
        id: 'lost_100',
        ownerId: 'user_1',
        itemName: 'Blue Umbrella',
        category: 'Accessories',
        description: 'Navy blue umbrella',
        brand: 'Generic',
        colour: 'Blue',
        dateLost: DateTime.now().subtract(const Duration(days: 12)),
        locationLost: 'Library',
        approximateValue: '₹500',
        status: 'ACTIVE',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
      );

      expect(item.daysRemaining, inInclusiveRange(17, 18));
      expect(item.countdownLabel, contains('days left'));

      final claimedItem = item.copyWith(status: 'CLAIMED');
      expect(claimedItem.countdownLabel, isNull);
    });
  });

  group('Unclaimed Countdown Widget Tests', () {
    testWidgets('ItemCard displays countdown badge for active report', (WidgetTester tester) async {
      final twelveDaysOld = DateTime.now().subtract(const Duration(days: 12));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              title: 'Lost Backpack',
              category: 'Bags',
              location: 'Main Gate',
              date: twelveDaysOld,
              createdAt: twelveDaysOld,
              status: 'ACTIVE',
              isLost: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('18 days left'), findsOneWidget);
    });

    testWidgets('ItemCard displays expired label for report older than 30 days', (WidgetTester tester) async {
      final fortyDaysOld = DateTime.now().subtract(const Duration(days: 40));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              title: 'Old Keys',
              category: 'Keys',
              location: 'Cafeteria',
              date: fortyDaysOld,
              createdAt: fortyDaysOld,
              status: 'UNCLAIMED',
              isLost: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unclaimed period expired'), findsOneWidget);
    });

    testWidgets('ItemCard does not display countdown badge for claimed report', (WidgetTester tester) async {
      final fiveDaysOld = DateTime.now().subtract(const Duration(days: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              title: 'Claimed Phone',
              category: 'Electronics',
              location: 'Block A',
              date: fiveDaysOld,
              createdAt: fiveDaysOld,
              status: 'CLAIMED',
              isLost: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('days left'), findsNothing);
      expect(find.text('Unclaimed period expired'), findsNothing);
    });

    testWidgets('ItemDetailsScreen displays countdown banner and spec row for active report', (WidgetTester tester) async {
      final twelveDaysOld = DateTime.now().subtract(const Duration(days: 12));
      final lostItem = LostItemModel(
        id: 'lost_101',
        ownerId: 'user_1',
        itemName: 'Lost Wallet',
        category: 'Personal',
        description: 'Leather wallet with ID',
        brand: 'Titan',
        colour: 'Brown',
        dateLost: twelveDaysOld,
        locationLost: 'Library',
        approximateValue: '₹2,000',
        status: 'ACTIVE',
        createdAt: twelveDaysOld,
        updatedAt: twelveDaysOld,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ItemDetailsScreen(lostItem: lostItem),
          ),
        ),
      );

      // Verify banner
      expect(find.text('18 days left remaining'), findsOneWidget);
      // Verify specification row
      expect(find.text('Unclaimed Deadline'), findsOneWidget);
      expect(find.text('18 days left'), findsOneWidget);
    });

    testWidgets('ItemDetailsScreen does not display countdown banner for claimed report', (WidgetTester tester) async {
      final fiveDaysOld = DateTime.now().subtract(const Duration(days: 5));
      final claimedItem = LostItemModel(
        id: 'lost_102',
        ownerId: 'user_1',
        itemName: 'Claimed Wallet',
        category: 'Personal',
        description: 'Leather wallet with ID',
        brand: 'Titan',
        colour: 'Brown',
        dateLost: fiveDaysOld,
        locationLost: 'Library',
        approximateValue: '₹2,000',
        status: 'CLAIMED',
        createdAt: fiveDaysOld,
        updatedAt: fiveDaysOld,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ItemDetailsScreen(lostItem: claimedItem),
          ),
        ),
      );

      expect(find.textContaining('days left'), findsNothing);
      expect(find.text('Unclaimed Deadline'), findsNothing);
    });
  });
}
