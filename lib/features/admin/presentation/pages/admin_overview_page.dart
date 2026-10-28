import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/admin_providers.dart';
import 'package:intl/intl.dart';

/// Admin Dashboard overview page showing key statistics,
/// report status summary, and recent activity.
class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final activityAsync = ref.watch(activityLogsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminUsersProvider.notifier).loadUsers();
        ref.read(lostItemsProvider.notifier).loadLostItems();
        ref.read(foundItemsProvider.notifier).loadFoundItems();
        ref.read(claimsProvider.notifier).loadClaims();
        ref.read(activityLogsProvider.notifier).loadLogs();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to the Admin Console',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage users, reports, and claims for the campus lost & found system.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stat cards grid
            statsAsync.when(
              data: (stats) => _buildStatsGrid(context, stats),
              loading: () => _buildStatsGrid(context, {}),
              error: (e, _) => _buildStatsGrid(context, {}),
            ),
            const SizedBox(height: 28),

            // Two-column layout for desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: statsAsync.when(
                          data: (stats) => _buildReportStatusSummary(stats),
                          loading: () => _buildReportStatusSummary({}),
                          error: (e, _) => _buildReportStatusSummary({}),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: _buildRecentActivitySection(activityAsync),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    statsAsync.when(
                      data: (stats) => _buildReportStatusSummary(stats),
                      loading: () => _buildReportStatusSummary({}),
                      error: (e, _) => _buildReportStatusSummary({}),
                    ),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(activityAsync),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    final statCards = [
      _StatCardData(
        'Total Users',
        stats['totalUsers'] ?? 0,
        Icons.people_rounded,
        const Color(0xFF6366F1),
        route: AppRoutes.adminUsers,
      ),
      _StatCardData(
        'Active Users',
        stats['activeUsers'] ?? 0,
        Icons.person_pin_circle_rounded,
        const Color(0xFF3B82F6),
      ),
      _StatCardData(
        'Lost Reports',
        stats['totalLostItems'] ?? 0,
        Icons.search_rounded,
        const Color(0xFFEF4444),
        route: AppRoutes.adminLostReports,
      ),
      _StatCardData(
        'Found Reports',
        stats['totalFoundItems'] ?? 0,
        Icons.inventory_2_rounded,
        const Color(0xFF10B981),
        route: AppRoutes.adminFoundReports,
      ),
      _StatCardData(
        'Claimed Items',
        stats['claimedItems'] ?? 0,
        Icons.check_circle_rounded,
        const Color(0xFF059669),
        route: AppRoutes.adminClaimed,
      ),
      _StatCardData(
        'Unclaimed Items',
        stats['unclaimedItems'] ?? 0,
        Icons.watch_later_rounded,
        const Color(0xFFD97706),
        route: AppRoutes.adminUnclaimed,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 900) crossAxisCount = 2;
        if (constraints.maxWidth < 550) crossAxisCount = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: statCards.length,
          itemBuilder: (context, index) {
            final card = statCards[index];
            return _buildStatCard(context, card);
          },
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, _StatCardData card) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${card.value}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (card.route != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: card.route != null
            ? InkWell(
                borderRadius: BorderRadius.circular(16),
                hoverColor: card.color.withValues(alpha: 0.04),
                onTap: () => context.go(card.route!),
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }

  Widget _buildReportStatusSummary(Map<String, int> stats) {
    final int active = (stats['activeLostItems'] ?? 0) + (stats['activeFoundItems'] ?? 0);
    final int claimed = stats['claimedItems'] ?? 0;
    final int unclaimed = stats['unclaimedItems'] ?? 0;
    final int total = active + claimed + unclaimed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Report Status Summary',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No report data available.',
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
              ),
            )
          else ...[
            _buildStatusProgressRow('Active', active, total, AppColors.statusActiveBg, AppColors.statusActiveText),
            const SizedBox(height: 16),
            _buildStatusProgressRow('Claimed', claimed, total, AppColors.statusClaimedBg, AppColors.statusClaimedText),
            const SizedBox(height: 16),
            _buildStatusProgressRow('Unclaimed', unclaimed, total, AppColors.statusUnclaimedBg, AppColors.statusUnclaimedText),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusProgressRow(String label, int count, int total, Color bgColor, Color progressColor) {
    final double percentage = total > 0 ? (count / total) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: bgColor,
          color: progressColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(AsyncValue activityAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          activityAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No recent activity.',
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
                  ),
                );
              }
              final recentLogs = logs.take(10).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                                  children: [
                                    TextSpan(text: log.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: ' ${log.action} '),
                                    TextSpan(text: log.targetType, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              if (log.details.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  log.details,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(log.timestamp),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Error loading activity: $e', style: const TextStyle(color: Colors.red)),
            )),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? route;

  _StatCardData(this.label, this.value, this.icon, this.color, {this.route});
}
