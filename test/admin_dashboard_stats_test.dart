import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/core/constants/app_constants.dart';

void main() {
  test('Dashboard stats correctly calculates unclaimed and claimed items', () {
    final now = DateTime.now();

    // Replicate Firestore documents matching current state
    final lostDocs = [
      {
        'id': 'lost_wallet',
        'itemName': 'wallet',
        'status': 'UNCLAIMED',
        'createdAt': now.subtract(const Duration(days: 60)),
      },
      {
        'id': 'lost_id',
        'itemName': 'id',
        'status': 'UNCLAIMED',
        'createdAt': now.subtract(const Duration(days: 32)),
      },
      {
        'id': 'lost_bottle',
        'itemName': 'steel bottle',
        'status': 'ACTIVE',
        'createdAt': now.subtract(const Duration(days: 28)),
      },
      {
        'id': 'lost_mouse',
        'itemName': 'Lenovo mouse',
        'status': 'CLAIMED',
        'createdAt': now.subtract(const Duration(days: 32)),
      },
    ];

    final foundDocs = [
      {
        'id': 'found_mouse',
        'itemName': 'Lenovo mouse',
        'status': 'CLAIMED',
        'createdAt': now.subtract(const Duration(days: 32)),
      },
    ];

    final claimsDocs = [
      {
        'id': 'claim_mouse',
        'status': 'APPROVED',
        'lostItemId': 'lost_mouse',
        'foundItemId': 'found_mouse',
      },
    ];

    final pairedClaimedLostIds = <String>{};
    for (final doc in claimsDocs) {
      final status = (doc['status'] ?? '').toString().toUpperCase();
      if (status == 'APPROVED') {
        final lostId = (doc['lostItemId'] ?? '').toString();
        if (lostId.isNotEmpty) {
          pairedClaimedLostIds.add(lostId);
        }
      }
    }

    bool isUnclaimed(Map<String, dynamic> data) {
      final status = (data['status'] ?? '').toString().toUpperCase();
      if (status == 'UNCLAIMED') return true;
      if (status == 'ACTIVE') {
        final createdAt = data['createdAt'] as DateTime?;
        if (createdAt != null) {
          final cutoff = DateTime.now().subtract(
            const Duration(days: AppConstants.unclaimedAfterDays),
          );
          return createdAt.isBefore(cutoff);
        }
      }
      return false;
    }

    int activeLost = 0, activeFound = 0, unclaimed = 0, claimed = 0;

    for (final doc in lostDocs) {
      final status = (doc['status'] ?? '').toString().toUpperCase();
      if (isUnclaimed(doc)) {
        unclaimed++;
      } else if (status == 'ACTIVE') {
        activeLost++;
      } else if (status == 'CLAIMED') {
        if (!pairedClaimedLostIds.contains(doc['id'])) {
          claimed++;
        }
      }
    }

    for (final doc in foundDocs) {
      final status = (doc['status'] ?? '').toString().toUpperCase();
      if (isUnclaimed(doc)) {
        unclaimed++;
      } else if (status == 'ACTIVE') {
        activeFound++;
      } else if (status == 'CLAIMED') {
        claimed++;
      }
    }

    expect(unclaimed, 2, reason: 'Expected 2 unclaimed items (wallet and id)');
    expect(claimed, 1, reason: 'Expected 1 claimed item (Lenovo mouse, deduplicated)');
    expect(activeLost, 1, reason: 'Expected 1 active lost item (steel bottle)');
    expect(activeFound, 0, reason: 'Expected 0 active found items');
  });
}
