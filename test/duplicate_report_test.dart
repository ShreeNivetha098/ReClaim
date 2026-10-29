import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/core/services/matching_service.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';

import 'match_notification_test.dart' show foundCalculator, foundUmbrella, lostCalculator, owner;

void main() {
  group('MatchingService same-item check', () {
    test("finds the owner's own found report of the same item", () {
      final duplicate = MatchingService.ownFoundReportOfSameItem(
        lostItem: lostCalculator(),
        foundItems: [foundCalculator(finderId: owner)],
      );
      expect(duplicate?.id, 'found_calc');
    });

    test("ignores someone else's found report of the same item", () {
      final duplicate = MatchingService.ownFoundReportOfSameItem(
        lostItem: lostCalculator(),
        foundItems: [foundCalculator()],
      );
      expect(duplicate, isNull);
    });

    test("ignores the owner's own report of a different item", () {
      final duplicate = MatchingService.ownLostReportOfSameItem(
        foundItem: foundUmbrella().copyWith(finderId: owner),
        lostItems: [lostCalculator()],
      );
      expect(duplicate, isNull);
    });

    test('ignores reports that are already closed', () {
      final duplicate = MatchingService.ownLostReportOfSameItem(
        foundItem: foundCalculator(finderId: owner),
        lostItems: [lostCalculator(status: 'RETURNED')],
      );
      expect(duplicate, isNull);
    });
  });

  group('reporting the same item as lost and found', () {
    test('a found report of an item the user reported lost is refused', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());

      await expectLater(
        repo.createFoundItem(foundCalculator(finderId: owner)),
        throwsA(isA<DuplicateReportException>()),
      );
      expect((await repo.getFoundItems()).where((i) => i.id == 'found_calc'), isEmpty);
    });

    test('a lost report of an item the user reported found is refused', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator(finderId: owner));

      await expectLater(
        repo.createLostItem(lostCalculator()),
        throwsA(isA<DuplicateReportException>()),
      );
      expect((await repo.getLostItems()).where((i) => i.id == 'lost_calc'), isEmpty);
    });

    test('editing a report into a copy of the other side is refused', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundUmbrella().copyWith(finderId: owner));

      final umbrella = (await repo.getFoundItems()).firstWhere((i) => i.id == 'found_umbrella');
      await expectLater(
        repo.updateFoundItem(foundCalculator(id: umbrella.id, finderId: owner)),
        throwsA(isA<DuplicateReportException>()),
      );
    });

    test('different users can still report the same item as lost and found', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundCalculator());

      expect((await repo.getFoundItems()).where((i) => i.id == 'found_calc'), hasLength(1));
    });
  });
}
