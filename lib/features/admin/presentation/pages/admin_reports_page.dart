import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/models/lost_item_model.dart';
import '../../../../shared/models/found_item_model.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_item_details_dialog.dart';

/// Admin report management page with tabbed Lost/Found tables and status actions.
class AdminReportsPage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const AdminReportsPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      final targetRoute = _tabController.index == 1
          ? AppRoutes.adminFoundReports
          : AppRoutes.adminLostReports;
      final currentPath = GoRouterState.of(context).uri.path;
      if (currentPath != targetRoute &&
          (currentPath == AppRoutes.adminLostReports || currentPath == AppRoutes.adminFoundReports)) {
        context.go(targetRoute);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AdminReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final targetIndex = widget.initialTabIndex.clamp(0, 1);
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters row
          _buildFilters(),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                final targetRoute = index == 1
                    ? AppRoutes.adminFoundReports
                    : AppRoutes.adminLostReports;
                final currentPath = GoRouterState.of(context).uri.path;
                if (currentPath != targetRoute) {
                  context.go(targetRoute);
                }
              },
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: '  Lost Items  '),
                Tab(text: '  Found Items  '),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLostItemsTab(),
                _buildFoundItemsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items by name, category, location...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, size: 20),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        _buildDropdown(
          value: _statusFilter,
          items: ['All', 'ACTIVE', 'CLAIMED', 'UNCLAIMED', 'RETURNED', 'CLOSED'],
          onChanged: (v) => setState(() => _statusFilter = v!),
          label: 'Status',
        ),
        _buildDropdown(
          value: _categoryFilter,
          items: ['All', 'Wallet', 'Electronics', 'Calculator', 'Books', 'ID Card', 'Keys', 'Bag', 'Other'],
          onChanged: (v) => setState(() => _categoryFilter = v!),
          label: 'Category',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          tooltip: 'Refresh',
          onPressed: () {
            ref.read(lostItemsProvider.notifier).loadLostItems();
            ref.read(foundItemsProvider.notifier).loadFoundItems();
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e', style: GoogleFonts.inter(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLostItemsTab() {
    final lostAsync = ref.watch(lostItemsProvider);
    return lostAsync.when(
      data: (items) {
        final filtered = _filterLostItems(items);
        if (filtered.isEmpty) return _emptyState('No lost items found');
        return _buildLostTable(filtered);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFoundItemsTab() {
    final foundAsync = ref.watch(foundItemsProvider);
    return foundAsync.when(
      data: (items) {
        final filtered = _filterFoundItems(items);
        if (filtered.isEmpty) return _emptyState('No found items found');
        return _buildFoundTable(filtered);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  List<LostItemModel> _filterLostItems(List<LostItemModel> items) {
    return items.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!item.itemName.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q) &&
            !item.locationLost.toLowerCase().contains(q) &&
            !(item.reporterName?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (_statusFilter != 'All' && item.status.toUpperCase() != _statusFilter) return false;
      if (_categoryFilter != 'All' && item.category != _categoryFilter) return false;
      return true;
    }).toList();
  }

  List<FoundItemModel> _filterFoundItems(List<FoundItemModel> items) {
    return items.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!item.itemName.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q) &&
            !item.locationFound.toLowerCase().contains(q) &&
            !(item.reporterName?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (_statusFilter != 'All' && item.status.toUpperCase() != _statusFilter) return false;
      if (_categoryFilter != 'All' && item.category != _categoryFilter) return false;
      return true;
    }).toList();
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
              headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              dataTextStyle: GoogleFonts.inter(fontSize: 13),
              columns: const [
                DataColumn(label: Text('ITEM NAME')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('REPORTER')),
                DataColumn(label: Text('LOCATION')),
                DataColumn(label: Text('DATE LOST')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item.itemName, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                  DataCell(Text(item.category)),
                  DataCell(Text(item.reporterName ?? 'Unknown')),
                  DataCell(Text(item.locationLost, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(DateFormat('MMM d, yyyy').format(item.dateLost))),
                  DataCell(_statusChip(item.status)),
                  DataCell(_buildItemActions(item.id, item.status, isLost: true, item: item)),
                ]);
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
              headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              dataTextStyle: GoogleFonts.inter(fontSize: 13),
              columns: const [
                DataColumn(label: Text('ITEM NAME')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('REPORTER')),
                DataColumn(label: Text('LOCATION')),
                DataColumn(label: Text('DATE FOUND')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item.itemName, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                  DataCell(Text(item.category)),
                  DataCell(Text(item.reporterName ?? 'Unknown')),
                  DataCell(Text(item.locationFound, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(DateFormat('MMM d, yyyy').format(item.dateFound))),
                  DataCell(_statusChip(item.status)),
                  DataCell(_buildItemActions(item.id, item.status, isLost: false, item: item)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status.toUpperCase()) {
      case 'ACTIVE': bg = AppColors.statusActiveBg; fg = AppColors.statusActiveText; break;
      case 'CLAIMED': bg = AppColors.statusClaimedBg; fg = AppColors.statusClaimedText; break;
      case 'UNCLAIMED': bg = AppColors.statusUnclaimedBg; fg = AppColors.statusUnclaimedText; break;
      case 'RETURNED': bg = AppColors.statusReturnedBg; fg = AppColors.statusReturnedText; break;
      case 'CLOSED': bg = AppColors.statusClosedBg; fg = AppColors.statusClosedText; break;
      default: bg = AppColors.statusMatchedBg; fg = AppColors.statusMatchedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildItemActions(String itemId, String status, {required bool isLost, required dynamic item}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
          tooltip: 'View Details',
          onPressed: () => _showItemDetails(item, isLost: isLost),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) => _handleItemAction(action, itemId, isLost: isLost),
          itemBuilder: (_) => [
            if (status.toUpperCase() == 'ACTIVE')
              const PopupMenuItem(value: 'UNCLAIMED', child: Text('Mark as Unclaimed')),
            if (status.toUpperCase() != 'CLOSED')
              const PopupMenuItem(value: 'CLOSED', child: Text('Close Report')),
            if (status.toUpperCase() == 'CLAIMED')
              const PopupMenuItem(value: 'RETURNED', child: Text('Mark as Returned')),
            const PopupMenuItem(value: 'DELETE', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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

  Future<void> _handleItemAction(String action, String itemId, {required bool isLost}) async {
    final repo = ref.read(repositoryProvider);
    final currentUser = ref.read(currentUserProvider);

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

    // Log activity
    await ref.read(adminRepositoryProvider).logActivity(
      actorId: currentUser?.uid ?? '',
      actorName: currentUser?.name ?? '',
      action: action == 'DELETE' ? 'ITEM_DELETED' : 'STATUS_CHANGED',
      targetType: isLost ? 'lostItem' : 'foundItem',
      targetId: itemId,
      details: action == 'DELETE' ? 'Deleted item' : 'Status changed to $action',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'DELETE' ? 'Item deleted' : 'Status updated to $action'),
          backgroundColor: action == 'DELETE' ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
