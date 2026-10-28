import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/core/constants/app_constants.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/shared/models/claim_model.dart';
import 'package:reclaim/shared/models/notification_model.dart';

import 'match_notification_test.dart' show finder, foundCalculator, foundUmbrella, lostCalculator, owner;

const claimant = 'claimant_1';

Future<List<NotificationModel>> notificationsOfType(
  ReClaimRepository repo,
  String userId,
  String type,
) async {
  final all = await repo.getNotifications(userId);
  return all.where((n) => n.userId == userId && n.type == type).toList();
}

ClaimModel claimFor(String foundItemId) {
  final now = DateTime.now();
  return ClaimModel(
    id: 'claim_test',
    itemId: foundItemId,
    lostItemId: '',
    foundItemId: foundItemId,
    claimantId: claimant,
    verificationAnswer: 'My roll number is engraved on the back',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('owner actions on their own reports', () {
    test('editing a lost report saves the new details but keeps owner and status', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());

      final original = (await repo.getLostItems()).firstWhere((i) => i.id == 'lost_calc');
      await repo.updateLostItem(original.copyWith(locationLost: 'Block B Lab 3', colour: 'Black'));

      final edited = (await repo.getLostItems()).firstWhere((i) => i.id == 'lost_calc');
      expect(edited.locationLost, 'Block B Lab 3');
      expect(edited.colour, 'Black');
      expect(edited.ownerId, owner);
      expect(edited.status, 'ACTIVE');
    });

    test('editing a lost report so it now matches notifies its owner', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator());
      await repo.createLostItem(lostCalculator().copyWith(
        itemName: 'Water bottle',
        category: 'Bottle',
        description: 'Steel bottle',
        brand: 'Milton',
        colour: 'Blue',
        locationLost: 'Gym',
      ));
      expect(await notificationsOfType(repo, owner, 'POTENTIAL_MATCH'), isEmpty);

      final mine = (await repo.getLostItems()).firstWhere((i) => i.id == 'lost_calc');
      await repo.updateLostItem(lostCalculator().copyWith(createdAt: mine.createdAt));

      expect(await notificationsOfType(repo, owner, 'POTENTIAL_MATCH'), hasLength(1));
    });

    test('a recovered lost report is closed and no longer matched', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.markLostItemRecovered('lost_calc');

      final closed = (await repo.getLostItems()).firstWhere((i) => i.id == 'lost_calc');
      expect(closed.status, AppConstants.statusReturned);

      await repo.createFoundItem(foundCalculator());
      expect(await notificationsOfType(repo, owner, 'POTENTIAL_MATCH'), isEmpty);
    });

    test('a found report marked returned is closed', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundUmbrella());
      await repo.markFoundItemReturned('found_umbrella');

      final closed = (await repo.getFoundItems()).firstWhere((i) => i.id == 'found_umbrella');
      expect(closed.status, AppConstants.statusReturned);
      expect(closed.finderId, finder);
    });

    test('deleting own reports removes them', () async {
      final repo = ReClaimRepository();
      await repo.createLostItem(lostCalculator());
      await repo.createFoundItem(foundUmbrella());

      await repo.deleteOwnLostItem(lostCalculator());
      await repo.deleteOwnFoundItem(foundUmbrella());

      expect((await repo.getLostItems()).where((i) => i.id == 'lost_calc'), isEmpty);
      expect((await repo.getFoundItems()).where((i) => i.id == 'found_umbrella'), isEmpty);
    });
  });

  group('claim decision notifications', () {
    test('an approved claim tells the claimant where to collect the item', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator());
      await repo.createClaim(claimFor('found_calc'));

      await repo.updateClaimStatus('claim_test', 'APPROVED');

      final approved = await notificationsOfType(repo, claimant, 'CLAIM_APPROVED');
      expect(approved, hasLength(1));
      expect(approved.first.targetId, 'found_calc');
      expect(approved.first.itemType, 'FOUND');
      expect(approved.first.title, contains('Casio fx-991EX Calculator'));
      expect(await notificationsOfType(repo, finder, 'CLAIM_APPROVED'), isEmpty);
    });

    test('a rejected claim tells the claimant', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator());
      await repo.createClaim(claimFor('found_calc'));

      await repo.updateClaimStatus('claim_test', 'REJECTED');

      expect(await notificationsOfType(repo, claimant, 'CLAIM_REJECTED'), hasLength(1));
      expect(await notificationsOfType(repo, claimant, 'CLAIM_APPROVED'), isEmpty);
    });

    test('other status changes send no decision notification', () async {
      final repo = ReClaimRepository();
      await repo.createFoundItem(foundCalculator());
      await repo.createClaim(claimFor('found_calc'));

      await repo.updateClaimStatus('claim_test', 'PENDING');

      expect(await notificationsOfType(repo, claimant, 'CLAIM_APPROVED'), isEmpty);
      expect(await notificationsOfType(repo, claimant, 'CLAIM_REJECTED'), isEmpty);
    });
  });
}
