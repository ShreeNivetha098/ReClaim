import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/models/lost_item_model.dart';
import '../../../../shared/models/found_item_model.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_item_details_dialog.dart';

/// Dedicated Admin page for displaying and managing UNCLAIMED items.
class AdminUnclaimedPage extends ConsumerStatefulWidget {
  const AdminUnclaimedPage({super.key});

  @override
  ConsumerState<AdminUnclaimedPage> createState() => _AdminUnclaimedPageState();
}

class _AdminUnclaimedPageState extends ConsumerState<AdminUnclaimedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    ref.read(lostItemsProvider.notifier).loadLostItems();
    ref.read(foundItemsProvider.notifier).loadFoundItems();
  }

  @override
  Widget build(BuildContext context) {
    final lostAsync = ref.watch(lostItemsProvider);
    final foundAsync = ref.watch(foundItemsProvider);

    final isLoading = (lostAsync.isLoading && !lostAsync.hasValue) ||
        (foundAsync.isLoading && !foundAsync.hasValue);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasError = (lostAsync.hasError && !lostAsync.hasValue) ||
        (foundAsync.hasError && !foundAsync.hasValue);

    if (hasError) {
      final errorMsg = lostAsync.error?.toString() ??
          foundAsync.error?.toString() ??
          'Error loading data';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Error loading unclaimed items: $errorMsg',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allLost = lostAsync.value ?? [];
    final allFound = foundAsync.value ?? [];

    // Filter strictly for documents with status == UNCLAIMED
    final unclaimedLost = allLost
        .where((item) => item.status.toUpperCase() == 'UNCLAIMED')
        .toList();

    final unclaimedFound = allFound
        .where((item) => item.status.toUpperCase() == 'UNCLAIMED')
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text(
            'Unclaimed Items',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Items that have remained unresolved beyond the defined holding period.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Search and Controls Bar
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search unclaimed items...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                tooltip: 'Refresh data',
                onPressed: _refreshData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lost / Found Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: '  Lost Items (${unclaimedLost.length})  '),
                Tab(text: '  Found Items (${unclaimedFound.length})  '),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLostTab(unclaimedLost),
                _buildFoundTab(unclaimedFound),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLostTab(List<LostItemModel> unclaimedLost) {
    if (unclaimedLost.isEmpty) {
      return _buildEmptyState('No unclaimed lost items found.');
    }

    final filtered = unclaimedLost.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final nameMatch = item.itemName.toLowerCase().contains(q);
      final categoryMatch = item.category.toLowerCase().contains(q);
      final locationMatch = item.locationLost.toLowerCase().contains(q);
      final reporterMatch =
          item.reporterName?.toLowerCase().contains(q) ?? false;
      return nameMatch || categoryMatch || locationMatch || reporterMatch;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No matching unclaimed items found.');
    }

    return _buildLostTable(filtered);
  }

  Widget _buildFoundTab(List<FoundItemModel> unclaimedFound) {
    if (unclaimedFound.isEmpty) {
      return _buildEmptyState('No unclaimed found items found.');
    }

    final filtered = unclaimedFound.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final nameMatch = item.itemName.toLowerCase().contains(q);
      final categoryMatch = item.category.toLowerCase().contains(q);
      final locationMatch = item.locationFound.toLowerCase().contains(q);
      final reporterMatch =
          item.reporterName?.toLowerCase().contains(q) ?? false;
      return nameMatch || categoryMatch || locationMatch || reporterMatch;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No matching unclaimed items found.');
    }

    return _buildFoundTable(filtered);
  }

  Widget _buildLostTable(List<LostItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columnSpacing: 24,
              headingTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              columns: const [
                DataColumn(label: Text('ITEM NAME')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('REPORTER NAME')),
                DataColumn(label: Text('LOCATION')),
                DataColumn(label: Text('DATE LOST')),
                DataColumn(label: Text('DATE REPORTED')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map((item) {
                final reporter = (item.reporterName != null &&
                        item.reporterName!.trim().isNotEmpty)
                    ? item.reporterName!
                    : 'Unknown user';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        item.itemName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(item.category)),
                    DataCell(Text(reporter)),
                    DataCell(Text(
                      item.locationLost.isNotEmpty
                          ? item.locationLost
                          : 'Not specified',
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Text(DateFormat('MMM d, yyyy').format(item.dateLost))),
                    DataCell(Text(DateFormat('MMM d, yyyy').format(item.createdAt))),
                    DataCell(_statusChip(item.status)),
                    DataCell(
                      _buildRowActions(
                        item: item,
                        isLost: true,
                        itemId: item.id,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoundTable(List<FoundItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columnSpacing: 24,
              headingTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              columns: const [
                DataColumn(label: Text('ITEM NAME')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('REPORTER NAME')),
                DataColumn(label: Text('LOCATION')),
                DataColumn(label: Text('DATE FOUND')),
                DataColumn(label: Text('DATE REPORTED')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map((item) {
                final reporter = (item.reporterName != null &&
                        item.reporterName!.trim().isNotEmpty)
                    ? item.reporterName!
                    : 'Unknown user';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        item.itemName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(item.category)),
                    DataCell(Text(reporter)),
                    DataCell(Text(
                      item.locationFound.isNotEmpty
                          ? item.locationFound
                          : 'Not specified',
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Text(DateFormat('MMM d, yyyy').format(item.dateFound))),
                    DataCell(Text(DateFormat('MMM d, yyyy').format(item.createdAt))),
                    DataCell(_statusChip(item.status)),
                    DataCell(
                      _buildRowActions(
                        item: item,
                        isLost: false,
                        itemId: item.id,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusUnclaimedBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.statusUnclaimedText,
        ),
      ),
    );
  }

  Widget _buildRowActions({
    required dynamic item,
    required bool isLost,
    required String itemId,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: Text(
            'View Details',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _showItemDetails(item, isLost: isLost),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) => _handleItemAction(action, itemId, isLost: isLost),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'CLOSED', child: Text('Close Report')),
            const PopupMenuItem(
              value: 'DELETE',
              child: Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ],
    );
  }

  void _showItemDetails(dynamic item, {required bool isLost}) {
    showDialog(
      context: context,
      builder: (context) => AdminItemDetailsDialog(
        item: item,
        isLost: isLost,
        onAction: (action) {
          Navigator.pop(context);
          _handleItemAction(action, item.id, isLost: isLost);
        },
      ),
    );
  }

  Future<void> _handleItemAction(String action, String itemId,
      {required bool isLost}) async {
    final repo = ref.read(repositoryProvider);
    final currentUser = ref.read(currentUserProvider);

    try {
      if (action == 'DELETE') {
        if (isLost) {
          await repo.deleteLostItem(itemId);
          ref.read(lostItemsProvider.notifier).loadLostItems();
        } else {
          await repo.deleteFoundItem(itemId);
          ref.read(foundItemsProvider.notifier).loadFoundItems();
        }
      } else {
        if (isLost) {
          await repo.updateLostItemStatus(itemId, action);
          ref.read(lostItemsProvider.notifier).loadLostItems();
        } else {
          await repo.updateFoundItemStatus(itemId, action);
          ref.read(foundItemsProvider.notifier).loadFoundItems();
        }
      }

      await ref.read(adminRepositoryProvider).logActivity(
            actorId: currentUser?.uid ?? '',
            actorName: currentUser?.name ?? '',
            action: action == 'DELETE' ? 'ITEM_DELETED' : 'STATUS_CHANGED',
            targetType: isLost ? 'lostItem' : 'foundItem',
            targetId: itemId,
            details: action == 'DELETE'
                ? 'Deleted unclaimed item'
                : 'Status changed to $action',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'DELETE'
                ? 'Item deleted'
                : 'Status updated to $action'),
            backgroundColor:
                action == 'DELETE' ? AppColors.error : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
