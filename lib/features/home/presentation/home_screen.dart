import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/item_card.dart';
import '../../lost_items/presentation/report_lost_item_screen.dart';
import '../../found_items/presentation/report_found_item_screen.dart';
import '../../item_details/presentation/item_details_screen.dart';
import '../../matching/presentation/potential_matches_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToNotifications;

  const HomeScreen({
    super.key,
    required this.onNavigateToSearch,
    required this.onNavigateToNotifications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final lostItemsAsync = ref.watch(lostItemsProvider);
    final foundItemsAsync = ref.watch(foundItemsProvider);

    final isAdmin = user?.role.toLowerCase() == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.find_in_page_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ReClaim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Campus Lost & Found',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Demo Role (Student/Admin)',
            onPressed: () {
              final newRole = isAdmin ? 'Student' : 'Admin';
              ref.read(currentUserProvider.notifier).switchRoleForDemo(newRole);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched user role to $newRole for demo testing'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: onNavigateToNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(lostItemsProvider.notifier).loadLostItems();
          ref.read(foundItemsProvider.notifier).loadFoundItems();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user?.name ?? 'Student'} 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.department ?? 'Department'} • ${user?.role ?? 'Student'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                            label: const Text('Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Embedded Quick Search Bar
                    GestureDetector(
                      onTap: onNavigateToSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded, color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text(
                              'Search lost items, calculators, wallets...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Cards (Report Lost / Report Found)
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'Report Lost Item',
                      subtitle: 'Misplaced an item?',
                      icon: Icons.search_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportLostItemScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'Report Found Item',
                      subtitle: 'Found someone\'s item?',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportFoundItemScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Potential Match Smart Notification Card
              _buildPotentialMatchBanner(context, ref, lostItemsAsync),

              const SizedBox(height: 24),

              // Recent Lost Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Lost Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: onNavigateToSearch,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              lostItemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No lost items reported yet.'),
                    );
                  }
                  final recent = items.take(4).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: recent.length,
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      return ItemCard(
                        title: item.itemName,
                        category: item.category,
                        location: item.locationLost,
                        date: item.dateLost,
                        imageUrl: item.imageUrl,
                        status: item.status,
                        isLost: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(lostItem: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading lost items: $err'),
              ),
              const SizedBox(height: 28),

              // Recent Found Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Found Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: onNavigateToSearch,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              foundItemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No found items reported yet.'),
                    );
                  }
                  final recent = items.take(4).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: recent.length,
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      return ItemCard(
                        title: item.itemName,
                        category: item.category,
                        location: item.locationFound,
                        date: item.dateFound,
                        imageUrl: item.imageUrl,
                        status: item.status,
                        isLost: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(foundItem: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error loading found items: $err'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPotentialMatchBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue lostItemsAsync,
  ) {
    return lostItemsAsync.when(
      data: (lostItems) {
        if (lostItems.isEmpty) return const SizedBox.shrink();
        final firstLost = lostItems.first;
        final matches = ref.watch(potentialMatchesProvider(firstLost));
        if (matches.isEmpty) return const SizedBox.shrink();

        final topMatch = matches.first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accentDark, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Smart Match Notification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${topMatch.matchPercentage.toStringAsFixed(0)}% MATCH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Found item "${topMatch.foundItem.itemName}" matches your reported lost item "${firstLost.itemName}".',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PotentialMatchesScreen(lostItem: firstLost),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('View Potential Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }
}
