import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../providers/admin_providers.dart';
import '../../services/recovery_stats.dart';

/// Recovery statistics and system usage for administrators.
class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(recoveryStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminUsersProvider.notifier).loadUsers();
        ref.read(lostItemsProvider.notifier).loadLostItems();
        ref.read(foundItemsProvider.notifier).loadFoundItems();
        ref.read(claimsProvider.notifier).loadClaims();
      },
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load analytics: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HeadlineTiles(stats: stats),
            const SizedBox(height: 20),
            _Panel(
              title: 'Reports per month',
              subtitle: 'New lost and found reports over the last 6 months',
              trailing: const _Legend(entries: [('Lost', AppColors.lost), ('Found', AppColors.found)]),
              child: _MonthlyChart(monthly: stats.monthly),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final category = _Panel(
                  title: 'Recovery by category',
                  subtitle: 'Share of reports whose item got back to its owner',
                  child: _CategoryBars(categories: stats.byCategory),
                );
                final hotspots = _Panel(
                  title: 'Where items get lost',
                  subtitle: 'Most reported places for lost items',
                  child: _HotspotBars(hotspots: stats.lostHotspots),
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: category),
                          const SizedBox(width: 20),
                          Expanded(child: hotspots),
                        ],
                      )
                    : Column(children: [category, const SizedBox(height: 20), hotspots]);
              },
            ),
            const SizedBox(height: 20),
            _Panel(
              title: 'Claim outcomes',
              subtitle: 'Decisions on ownership claims so far',
              child: _ClaimOutcomes(stats: stats),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline numbers
// ---------------------------------------------------------------------------

class _HeadlineTiles extends StatelessWidget {
  final RecoveryStats stats;

  const _HeadlineTiles({required this.stats});

  String _percent(double value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final days = stats.averageDaysToRecover;
    final tiles = [
      _Tile(
        icon: Icons.volunteer_activism_rounded,
        label: 'Recovery rate',
        value: stats.totalReports == 0 ? '—' : _percent(stats.recoveryRate),
        detail: '${stats.recoveredReports} of ${stats.totalReports} reports',
      ),
      _Tile(
        icon: Icons.timer_rounded,
        label: 'Time to recover',
        value: days == null ? '—' : (days < 1 ? '< 1 day' : '${days.toStringAsFixed(1)} days'),
        detail: days == null ? 'No items recovered yet' : 'Average, report to recovery',
      ),
      _Tile(
        icon: Icons.fact_check_rounded,
        label: 'Claims approved',
        value: stats.claimsDecided == 0 ? '—' : _percent(stats.approvalRate),
        detail: '${stats.claimsPending} waiting for review',
      ),
      _Tile(
        icon: Icons.verified_rounded,
        label: 'Verified users',
        value: stats.users == 0 ? '—' : _percent(stats.verifiedRate),
        detail: '${stats.verifiedUsers} of ${stats.users} users',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 560 ? 2 : 1);
        final width = (constraints.maxWidth - 16 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  const _Tile({required this.icon, required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.statusActiveBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _text(13, FontWeight.w600, AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: _text(26, FontWeight.w800, AppColors.textPrimary)),
                Text(detail, style: _text(12, FontWeight.w500, AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

/// Grouped columns: lost and found reports for each month, labelled with
/// their values because the two colours are light against white.
class _MonthlyChart extends StatelessWidget {
  final List<MonthlyCount> monthly;

  const _MonthlyChart({required this.monthly});

  static const _plotHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final peak = monthly.fold<int>(0, (m, c) => math.max(m, math.max(c.lost, c.found)));
    if (peak == 0) return const _Empty('No reports in the last 6 months.');

    return SizedBox(
      height: _plotHeight + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final month in monthly)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _column(month.lost, peak, AppColors.lost, 'Lost', month.month),
                      const SizedBox(width: 2),
                      _column(month.found, peak, AppColors.found, 'Found', month.month),
                    ],
                  ),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Text(DateFormat('MMM yy').format(month.month), style: _text(12, FontWeight.w600, AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _column(int value, int peak, Color color, String series, DateTime month) {
    final height = value == 0 ? 0.0 : math.max(4.0, _plotHeight * value / peak);
    return Tooltip(
      message: '$series reports, ${DateFormat('MMMM yyyy').format(month)}: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: _text(11, FontWeight.w700, AppColors.textSecondary)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: height),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, h, _) => Container(
              width: 22,
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row per category: a track for all its reports, filled up to the
/// share that was recovered.
class _CategoryBars extends StatelessWidget {
  final List<CategoryRecovery> categories;

  const _CategoryBars({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const _Empty('No reports yet.');
    return Column(
      children: [
        for (final c in categories.take(8))
          Tooltip(
            message: '${c.category}: ${c.recovered} of ${c.total} recovered',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(width: 110, child: Text(c.category, style: _text(13, FontWeight.w600, AppColors.textPrimary))),
                  Expanded(child: _Bar(fraction: c.rate, color: AppColors.found)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${(c.rate * 100).round()}% · ${c.recovered}/${c.total}',
                      textAlign: TextAlign.right,
                      style: _text(12, FontWeight.w700, AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HotspotBars extends StatelessWidget {
  final List<MapEntry<String, int>> hotspots;

  const _HotspotBars({required this.hotspots});

  @override
  Widget build(BuildContext context) {
    if (hotspots.isEmpty) return const _Empty('No lost reports with a location yet.');
    final peak = hotspots.first.value;
    return Column(
      children: [
        for (final spot in hotspots)
          Tooltip(
            message: '${spot.key}: ${spot.value} lost ${spot.value == 1 ? 'report' : 'reports'}',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 140,
                    child: Text(spot.key, overflow: TextOverflow.ellipsis, style: _text(13, FontWeight.w600, AppColors.textPrimary)),
                  ),
                  Expanded(child: _Bar(fraction: spot.value / peak, color: AppColors.lost)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 28,
                    child: Text('${spot.value}', textAlign: TextAlign.right, style: _text(12, FontWeight.w700, AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Claim decisions as one segmented bar, with icon-and-label legend so the
/// status is never shown by colour alone.
class _ClaimOutcomes extends StatelessWidget {
  final RecoveryStats stats;

  const _ClaimOutcomes({required this.stats});

  @override
  Widget build(BuildContext context) {
    final parts = [
      (Icons.check_circle_rounded, 'Approved', stats.claimsApproved, AppColors.success),
      (Icons.hourglass_top_rounded, 'Pending', stats.claimsPending, AppColors.warning),
      (Icons.cancel_rounded, 'Rejected', stats.claimsRejected, AppColors.error),
    ];
    final total = parts.fold<int>(0, (sum, p) => sum + p.$3);
    if (total == 0) return const _Empty('No claims yet.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final (index, p) in parts.indexed)
                  if (p.$3 > 0)
                    Expanded(
                      flex: p.$3,
                      child: Tooltip(
                        message: '${p.$2}: ${p.$3}',
                        child: Container(
                          // 2px surface gap between segments
                          margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
                          color: p.$4,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            for (final p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.$1, size: 18, color: p.$4),
                  const SizedBox(width: 6),
                  Text('${p.$2}: ', style: _text(13, FontWeight.w600, AppColors.textSecondary)),
                  Text('${p.$3}', style: _text(13, FontWeight.w800, AppColors.textPrimary)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

final _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.divider),
);

TextStyle _text(double size, FontWeight weight, Color color) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color);

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _Panel({required this.title, required this.subtitle, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _text(16, FontWeight.w800, AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _text(12.5, FontWeight.w500, AppColors.textMuted)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(String, Color)> entries;

  const _Legend({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        for (final (label, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(label, style: _text(12.5, FontWeight.w600, AppColors.textSecondary)),
            ],
          ),
      ],
    );
  }
}

/// Horizontal bar on a light track; [fraction] is 0 to 1.
class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;

  const _Bar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text, style: _text(13, FontWeight.w500, AppColors.textMuted))),
    );
  }
}
