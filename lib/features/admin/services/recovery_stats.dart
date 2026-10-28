import '../../../core/constants/app_constants.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/models/user_model.dart';

/// Reports for one calendar month.
class MonthlyCount {
  final DateTime month;
  final int lost;
  final int found;

  const MonthlyCount(this.month, this.lost, this.found);
}

/// How many reports a category has and how many of them were recovered.
class CategoryRecovery {
  final String category;
  final int total;
  final int recovered;

  const CategoryRecovery(this.category, this.total, this.recovered);

  double get rate => total == 0 ? 0 : recovered / total;
}

/// Recovery statistics for the admin Analytics page, computed from the
/// reports, claims and users already loaded by the dashboard.
class RecoveryStats {
  /// A report counts as recovered once its item is back with its owner.
  static const recoveredStatuses = {AppConstants.statusClaimed, AppConstants.statusReturned};

  final int totalReports;
  final int recoveredReports;
  final int lostReports;
  final int lostRecovered;
  final int foundReports;
  final int foundRecovered;

  /// Average days from report to recovery, or null when nothing is recovered yet.
  final double? averageDaysToRecover;

  final int claimsApproved;
  final int claimsRejected;
  final int claimsPending;

  final int users;
  final int verifiedUsers;

  /// Oldest first; always [monthCount] entries, including empty months.
  final List<MonthlyCount> monthly;

  /// Busiest categories first.
  final List<CategoryRecovery> byCategory;

  /// Places where items are most often lost, busiest first.
  final List<MapEntry<String, int>> lostHotspots;

  const RecoveryStats._({
    required this.totalReports,
    required this.recoveredReports,
    required this.lostReports,
    required this.lostRecovered,
    required this.foundReports,
    required this.foundRecovered,
    required this.averageDaysToRecover,
    required this.claimsApproved,
    required this.claimsRejected,
    required this.claimsPending,
    required this.users,
    required this.verifiedUsers,
    required this.monthly,
    required this.byCategory,
    required this.lostHotspots,
  });

  double get recoveryRate => totalReports == 0 ? 0 : recoveredReports / totalReports;
  double get verifiedRate => users == 0 ? 0 : verifiedUsers / users;
  int get claimsDecided => claimsApproved + claimsRejected;
  double get approvalRate => claimsDecided == 0 ? 0 : claimsApproved / claimsDecided;

  factory RecoveryStats.compute({
    required List<LostItemModel> lost,
    required List<FoundItemModel> found,
    required List<ClaimModel> claims,
    required List<UserModel> users,
    DateTime? now,
    int monthCount = 6,
    int hotspotCount = 5,
  }) {
    bool isRecovered(String status) => recoveredStatuses.contains(status.toUpperCase());

    // Report-to-recovery time uses the last update, when the status changed.
    final recoveryDays = <double>[
      for (final item in lost)
        if (isRecovered(item.status)) item.updatedAt.difference(item.createdAt).inHours / 24,
      for (final item in found)
        if (isRecovered(item.status)) item.updatedAt.difference(item.createdAt).inHours / 24,
    ];

    final today = now ?? DateTime.now();
    final months = [
      for (var i = monthCount - 1; i >= 0; i--) DateTime(today.year, today.month - i),
    ];
    bool inMonth(DateTime d, DateTime m) => d.year == m.year && d.month == m.month;

    final categories = <String, ({int total, int recovered})>{};
    void addCategory(String category, String status) {
      final key = category.trim().isEmpty ? 'Other' : category.trim();
      final current = categories[key] ?? (total: 0, recovered: 0);
      categories[key] = (total: current.total + 1, recovered: current.recovered + (isRecovered(status) ? 1 : 0));
    }

    for (final item in lost) {
      addCategory(item.category, item.status);
    }
    for (final item in found) {
      addCategory(item.category, item.status);
    }

    final hotspots = <String, int>{};
    for (final item in lost) {
      final place = item.locationLost.trim();
      if (place.isEmpty || place.toUpperCase() == 'N/A') continue;
      // Group "central library" and "Central Library" together.
      final key = place[0].toUpperCase() + place.substring(1);
      final existing = hotspots.keys.where((k) => k.toLowerCase() == key.toLowerCase());
      final target = existing.isEmpty ? key : existing.first;
      hotspots[target] = (hotspots[target] ?? 0) + 1;
    }

    final lostRecovered = lost.where((i) => isRecovered(i.status)).length;
    final foundRecovered = found.where((i) => isRecovered(i.status)).length;

    return RecoveryStats._(
      totalReports: lost.length + found.length,
      recoveredReports: lostRecovered + foundRecovered,
      lostReports: lost.length,
      lostRecovered: lostRecovered,
      foundReports: found.length,
      foundRecovered: foundRecovered,
      averageDaysToRecover:
          recoveryDays.isEmpty ? null : recoveryDays.reduce((a, b) => a + b) / recoveryDays.length,
      claimsApproved: claims.where((c) => c.status.toUpperCase() == 'APPROVED').length,
      claimsRejected: claims.where((c) => c.status.toUpperCase() == 'REJECTED').length,
      claimsPending: claims.where((c) => c.status.toUpperCase() == 'PENDING').length,
      users: users.length,
      verifiedUsers: users.where((u) => u.isVerified).length,
      monthly: [
        for (final m in months)
          MonthlyCount(
            m,
            lost.where((i) => inMonth(i.createdAt, m)).length,
            found.where((i) => inMonth(i.createdAt, m)).length,
          ),
      ],
      byCategory: [
        for (final e in categories.entries) CategoryRecovery(e.key, e.value.total, e.value.recovered),
      ]..sort((a, b) => b.total.compareTo(a.total)),
      lostHotspots: (hotspots.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .take(hotspotCount)
          .toList(),
    );
  }
}
