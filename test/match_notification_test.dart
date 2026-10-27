import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/core/services/matching_service.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/shared/models/found_item_model.dart';
import 'package:reclaim/shared/models/lost_item_model.dart';
import 'package:reclaim/shared/models/notification_model.dart';

const owner = 'owner_1';
const finder = 'finder_1';

LostItemModel lostCalculator({String id = 'lost_calc', String ownerId = owner, String status = 'ACTIVE'}) {
  final now = DateTime.now();
  return LostItemModel(
    id: id,
    ownerId: ownerId,
    itemName: 'Casio fx-991EX Calculator',
    category: 'Stationery',
    description: 'Grey scientific calculator with my roll number on the back',
    brand: 'Casio',
    colour: 'Grey',
    dateLost: now,
    locationLost: 'Main Library',
    approximateValue: '1200',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

FoundItemModel foundCalculator({String id = 'found_calc', String finderId = finder}) {
  final now = DateTime.now();
  return FoundItemModel(
    id: id,
    finderId: finderId,
    itemName: 'Casio fx-991EX Calculator',
    category: 'Stationery',
    description: 'Grey scientific calculator, roll number on the back',
    brand: 'Casio',
    colour: 'Grey',
    dateFound: now,
    locationFound: 'Main Library',
    imageUrl: '',
    createdAt: now,
    updatedAt: now,
  );
}

FoundItemModel foundUmbrella() {
  final now = DateTime.now();
  return FoundItemModel(
    id: 'found_umbrella',
    finderId: finder,
    itemName: 'Umbrella',
    category: 'Accessories',
    description: 'Large striped umbrella',
    brand: 'Unknown',
    colour: 'Red',
    dateFound: now.subtract(const Duration(days: 20)),
    locationFound: 'Canteen',
    imageUrl: '',
    createdAt: now,
    updatedAt: now,
  );
}

Future<List<NotificationModel>> matchNotificationsFor(ReClaimRepository repo, String userId) async {
  final all = await repo.getNotifications(userId);
  return all.where((n) => n.type == 'POTENTIAL_MATCH' && n.userId == userId).toList();
}

void main() {
  group('MatchingService.findMatchesForFoundItem', () {
    test('finds the lost report a found item matches', () {
      final matches = MatchingService.findMatchesForFoundItem(
        foundItem: foundCalculator(),
        lostItems: [lostCalculator()],
        minThreshold: MatchingService.notifyThreshold,
      );
      expect(matches, hasLength(1));
      expect(matches.first.lostItem.id, 'lost_calc');
      expect(matches.first.matchPercentage, greaterThanOrEqualTo(MatchingService.notifyThreshold));
    });

    test('ignores unrelated items', () {
      final matches = MatchingService.findMatchesForFoundItem(
        foundItem: foundUmbrella(),
        lostItems: [lostCalculator()],
        minThreshold: MatchingService.notifyThreshold,
      );
      expect(matches, isEmpty);
    });

    test('ignores lost reports that are already closed', () {
      final matches = MatchingService.findMatchesForFoundItem(
        foundItem: foundCalculator(),
        lostItems: [lostCalculator(status: 'CLAIMED')],
      );
      expect(matches, isEmpty);
    });

    test("never matches a finder's own lost report", () {
      final matches = MatchingService.findMatchesForFoundItem(
        foundItem: foundCalculator(),
        lostItems: [lostCalculator(ownerId: finder)],
      );
      expect(matches, isEmpty);
    });

    test('scores are the same in both directions', () {
      final fromFound = MatchingService.findMatchesForFoundItem(
        foundItem: foundCalculator(),
        lostItems: [lostCalculator()],
      );
      final fromLost = MatchingService.findMatchesForLostItem(
        lostItem: lostCalculator(),
        foundItems: [foundCalculator()],
      );
      expect(fromFound.first.matchPercentage, fromLost.first.matchPercentage);
    });
  });

  group('match notifications', () {
    test('a new found item notifies only the lost report owner', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundCalculator());

      final ownerMatches = await matchNotificationsFor(repo, owner);
      expect(ownerMatches, hasLength(1));
      expect(ownerMatches.first.targetId, 'found_calc');
      expect(ownerMatches.first.lostItemId, 'lost_calc');
      expect(ownerMatches.first.itemType, 'FOUND');

      expect(await matchNotificationsFor(repo, finder), isEmpty);
    });

    test('a new lost report tells its owner about an existing found item', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator());
      await repo.createLostItem(lostCalculator());

      final ownerMatches = await matchNotificationsFor(repo, owner);
      expect(ownerMatches, hasLength(1));
      expect(ownerMatches.first.targetId, 'found_calc');
      expect(await matchNotificationsFor(repo, finder), isEmpty);
    });

    test('the same pair is never notified twice', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundCalculator());
      await repo.createFoundItem(foundCalculator());

      expect(await matchNotificationsFor(repo, owner), hasLength(1));
    });

    test('an unrelated found item sends no match notification', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundUmbrella());

      expect(await matchNotificationsFor(repo, owner), isEmpty);
    });
  });
}
