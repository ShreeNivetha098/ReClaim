import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lostItemsAsync = ref.watch(lostItemsProvider);
    final foundItemsAsync = ref.watch(foundItemsProvider);
    final claimsAsync = ref.watch(claimsProvider);
    final repo = ref.watch(repositoryProvider);

    final lostItems = lostItemsAsync.asData?.value ?? [];
    final foundItems = foundItemsAsync.asData?.value ?? [];
    final claims = claimsAsync.asData?.value ?? [];

    final pendingClaims = claims.where((c) => c.status == 'PENDING').toList();
    final approvedClaims = claims.where((c) => c.status == 'APPROVED').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console & Management'),
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending Claims'),
            Tab(text: 'User Management'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stat Overview Row
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('Lost Reports', '${lostItems.length}', AppColors.primary),
                  const SizedBox(width: 10),
                  _buildStatCard('Found Reports', '${foundItems.length}', AppColors.secondary),
                  const SizedBox(width: 10),
                  _buildStatCard('Pending Claims', '${pendingClaims.length}', AppColors.accentDark),
                  const SizedBox(width: 10),
                  _buildStatCard('Approved Claims', '${approvedClaims.length}', AppColors.secondaryDark),
                ],
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Claims Moderation Tab
                claimsAsync.when(
                  data: (claimsList) {
                    if (claimsList.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'No Pending Claims',
                        description: 'There are no item claims awaiting admin approval right now.',
                        icon: Icons.check_circle_outline,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: claimsList.length,
                      itemBuilder: (context, index) {
                        final claim = claimsList[index];
                        final isPending = claim.status == 'PENDING';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Claim ID: ${claim.id.substring(0, claim.id.length > 8 ? 8 : claim.id.length)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    StatusChip(status: claim.status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Claimant User ID: ${claim.claimantId}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Verification Answer:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(claim.verificationAnswer, style: const TextStyle(fontSize: 13)),
                                      if (claim.uniqueMarks.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Unique Marks / Serials:',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        Text(claim.uniqueMarks, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ],
                                  ),
                                ),

                                if (isPending) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Approve Claim',
                                          height: 40,
                                          type: CustomButtonType.secondary,
                                          onPressed: () async {
                                            await ref.read(claimsProvider.notifier).updateClaimStatus(claim.id, 'APPROVED');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Claim APPROVED! Item marked as CLAIMED.'),
                                                  backgroundColor: AppColors.success,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(color: AppColors.error),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () async {
                                            await ref.read(claimsProvider.notifier).updateClaimStatus(claim.id, 'REJECTED');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Claim REJECTED.'),
                                                  backgroundColor: AppColors.error,
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Reject Claim'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Error: $err'),
                ),

                // 2. User Management Tab
                FutureBuilder(
                  future: repo.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final users = snapshot.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  u.name.isNotEmpty ? u.name[0] : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${u.email} • ${u.role}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      '${u.department} (${u.rollNumber})',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u.isActive ? AppColors.statusReturnedBg : AppColors.statusClosedBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  u.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: u.isActive ? AppColors.statusReturnedText : AppColors.statusClosedText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // 3. Analytics Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campus Recovery Statistics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Total Lost Reports',
                        '${lostItems.length}',
                        'Reported misplacements on campus',
                        Icons.search_rounded,
                        AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Total Found Items',
                        '${foundItems.length}',
                        'Turned in by students & security desk',
                        Icons.inventory_2_outlined,
                        AppColors.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Items Claimed & Returned',
                        '${approvedClaims.length}',
                        'Successfully verified & handed back',
                        Icons.check_circle_outline,
                        AppColors.accentDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
