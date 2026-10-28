import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/features/admin/services/recovery_stats.dart';
import 'package:reclaim/shared/models/claim_model.dart';
import 'package:reclaim/shared/models/found_item_model.dart';
import 'package:reclaim/shared/models/lost_item_model.dart';
import 'package:reclaim/shared/models/user_model.dart';

final now = DateTime(2026, 10, 28, 12);

LostItemModel lost(String id, String category, String place, String status, DateTime created, [DateTime? updated]) {
  return LostItemModel(
    id: id,
    ownerId: 'o',
    itemName: id,
    category: category,
    description: '',
    brand: 'N/A',
    colour: 'N/A',
    dateLost: created,
    locationLost: place,
    approximateValue: 'N/A',
    status: status,
    createdAt: created,
    updatedAt: updated ?? created,
  );
}

FoundItemModel found(String id, String category, String status, DateTime created, [DateTime? updated]) {
  return FoundItemModel(
    id: id,
    finderId: 'f',
    itemName: id,
    category: category,
    description: '',
    brand: 'N/A',
    colour: 'N/A',
    dateFound: created,
    locationFound: 'Gym',
    imageUrl: '',
    status: status,
    createdAt: created,
    updatedAt: updated ?? created,
  );
}

ClaimModel claim(String status) => ClaimModel(
      id: status,
      itemId: 'f1',
      lostItemId: '',
      foundItemId: 'f1',
      claimantId: 'c',
      verificationAnswer: '',
      status: status,
      createdAt: now,
      updatedAt: now,
    );

UserModel user(String id, {bool verified = false}) {
  final u = UserModel(
    uid: id,
    name: id,
    email: '$id@psgtech.ac.in',
    phone: '',
    department: '',
    rollNumber: '',
    role: 'Student',
    createdAt: now,
    updatedAt: now,
  );
  return verified ? u.withVerification(status: 'VERIFIED', verifiedBy: 'Admin', verifiedAt: now) : u;
}

void main() {
  final day = const Duration(days: 1);

  late RecoveryStats stats;

  setUp(() {
    stats = RecoveryStats.compute(
      now: now,
      lost: [
        lost('wallet', 'Wallet', 'Central Library', 'RETURNED', now.subtract(day * 4), now.subtract(day * 2)),
        lost('keys', 'Keys', 'central library', 'ACTIVE', now.subtract(day * 40)),
        lost('calc', 'Calculator', 'Block B', 'ACTIVE', now.subtract(day * 1)),
        lost('id', 'ID Card', 'N/A', 'UNCLAIMED', now.subtract(day * 70)),
      ],
      found: [
        found('wallet2', 'Wallet', 'CLAIMED', now.subtract(day * 3), now.subtract(day * 2)),
        found('bottle', 'Bottle', 'ACTIVE', now.subtract(day * 1)),
      ],
      claims: [claim('APPROVED'), claim('APPROVED'), claim('REJECTED'), claim('PENDING')],
      users: [user('a', verified: true), user('b'), user('c'), user('d', verified: true)],
    );
  });

  test('recovery rate counts claimed and returned reports', () {
    expect(stats.totalReports, 6);
    expect(stats.recoveredReports, 2);
    expect(stats.recoveryRate, closeTo(2 / 6, 1e-9));
    expect(stats.lostRecovered, 1);
    expect(stats.foundRecovered, 1);
  });

  test('average time to recover uses report and recovery dates', () {
    // Wallet: 2 days, found wallet: 1 day.
    expect(stats.averageDaysToRecover, closeTo(1.5, 1e-9));
  });

  test('monthly counts cover the last 6 months including empty ones', () {
    expect(stats.monthly, hasLength(6));
    expect(stats.monthly.last.month, DateTime(2026, 10));
    expect(stats.monthly.first.month, DateTime(2026, 5));
    final october = stats.monthly.last;
    expect(october.lost, 2); // wallet, calc
    expect(october.found, 2);
    final september = stats.monthly[4];
    expect(september.lost, 1); // keys, 40 days ago
  });

  test('categories are ranked by reports with their recovery share', () {
    final wallet = stats.byCategory.first;
    expect(wallet.category, 'Wallet');
    expect(wallet.total, 2);
    expect(wallet.recovered, 2);
    expect(wallet.rate, 1.0);
  });

  test('hotspots group places regardless of case and skip N/A', () {
    expect(stats.lostHotspots.first.key, 'Central Library');
    expect(stats.lostHotspots.first.value, 2);
    expect(stats.lostHotspots.map((e) => e.key), isNot(contains('N/A')));
  });

  test('claims and verification rates', () {
    expect(stats.claimsApproved, 2);
    expect(stats.claimsRejected, 1);
    expect(stats.claimsPending, 1);
    expect(stats.approvalRate, closeTo(2 / 3, 1e-9));
    expect(stats.verifiedRate, 0.5);
  });

  test('no data gives zero rates and no average', () {
    final empty = RecoveryStats.compute(lost: [], found: [], claims: [], users: [], now: now);
    expect(empty.recoveryRate, 0);
    expect(empty.averageDaysToRecover, isNull);
    expect(empty.approvalRate, 0);
    expect(empty.byCategory, isEmpty);
    expect(empty.monthly.every((m) => m.lost == 0 && m.found == 0), isTrue);
  });
}
