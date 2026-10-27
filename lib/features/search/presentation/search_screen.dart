import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../item_details/presentation/item_details_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedStatus = 'All Active';
  final String _selectedSort = 'Newest';

  final List<String> _categories = [
    'All',
    'ID Card',
    'Wallet',
    'Keys',
    'Books',
    'Calculator',
    'Electronics',
    'Bag',
    'Bottle',
    'Documents',
    'Accessories',
    'Other',
  ];

  final List<String> _statusFilters = [
    'All Active',
    'Unclaimed',
    'Claimed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Returns the Firestore status value that corresponds to the selected
  /// filter label, or null when no specific status is being filtered.
  String? _resolveStatusFilter() {
    switch (_selectedStatus) {
      case 'All Active':
        return AppConstants.statusActive;
      case 'Unclaimed':
        return AppConstants.statusUnclaimed;
      case 'Claimed':
        return AppConstants.statusClaimed;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lostItemsAsync = ref.watch(lostItemsProvider);
    final foundItemsAsync = ref.watch(foundItemsProvider);
    final query = _searchController.text.trim().toLowerCase();
    final statusFilter = _resolveStatusFilter();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter Items'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Lost Items'),
            Tab(text: 'Found Items'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name, brand, color, location...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          selectedColor: _statusChipColor(status).withValues(alpha: 0.2),
                          avatar: isSelected
                              ? Icon(
                                  _statusChipIcon(status),
                                  size: 16,
                                  color: _statusChipColor(status),
                                )
                              : null,
                          labelStyle: TextStyle(
                            color: isSelected ? _statusChipColor(status) : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : 'All Active';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Chips Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // TabBar Views for Lost & Found search results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Lost Items Tab Results
                lostItemsAsync.when(
                  data: (items) {
                    var filtered = items.where((item) {
                      final matchesCategory =
                          _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
                      final matchesQuery = query.isEmpty ||
                          item.itemName.toLowerCase().contains(query) ||
                          item.description.toLowerCase().contains(query) ||
                          item.brand.toLowerCase().contains(query) ||
                          item.colour.toLowerCase().contains(query) ||
                          item.locationLost.toLowerCase().contains(query);
                      final matchesStatus = statusFilter == null ||
                          item.status.toUpperCase() == statusFilter;
                      return matchesCategory && matchesQuery && matchesStatus;
                    }).toList();

                    if (_selectedSort == 'Newest') {
                      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    } else {
                      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    }

                    if (filtered.isEmpty) {
                      return EmptyStateWidget(
                        title: 'No Lost Items Found',
                        description: _selectedStatus != 'All Active'
                            ? 'No $_selectedStatus lost items match your filters.'
                            : 'Try adjusting your search keywords or category filters.',
                        icon: Icons.search_off_rounded,
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ItemCard(
                          title: item.itemName,
                          category: item.category,
                          location: item.locationLost,
                          date: item.dateLost,
                          createdAt: item.createdAt,
                          imageUrl: item.imageUrl,
                          status: item.status,
                          isLost: true,
                          reporterName: item.reporterName,
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
                  error: (err, st) => Center(child: Text('Error loading search results: $err')),
                ),

                // Found Items Tab Results
                foundItemsAsync.when(
                  data: (items) {
                    var filtered = items.where((item) {
                      final matchesCategory =
                          _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
                      final matchesQuery = query.isEmpty ||
                          item.itemName.toLowerCase().contains(query) ||
                          item.description.toLowerCase().contains(query) ||
                          item.brand.toLowerCase().contains(query) ||
                          item.colour.toLowerCase().contains(query) ||
                          item.locationFound.toLowerCase().contains(query);
                      final matchesStatus = statusFilter == null ||
                          item.status.toUpperCase() == statusFilter;
                      return matchesCategory && matchesQuery && matchesStatus;
                    }).toList();

                    if (_selectedSort == 'Newest') {
                      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    } else {
                      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    }

                    if (filtered.isEmpty) {
                      return EmptyStateWidget(
                        title: 'No Found Items Found',
                        description: _selectedStatus != 'All Active'
                            ? 'No $_selectedStatus found items match your filters.'
                            : 'Try adjusting your search keywords or category filters.',
                        icon: Icons.find_in_page_outlined,
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ItemCard(
                          title: item.itemName,
                          category: item.category,
                          location: item.locationFound,
                          date: item.dateFound,
                          createdAt: item.createdAt,
                          imageUrl: item.imageUrl,
                          status: item.status,
                          isLost: false,
                          reporterName: item.reporterName,
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
                  error: (err, st) => Center(child: Text('Error loading search results: $err')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a color associated with the given status filter label.
  Color _statusChipColor(String status) {
    switch (status) {
      case 'Unclaimed':
        return AppColors.statusUnclaimedText;
      case 'Claimed':
        return AppColors.statusClaimedText;
      case 'All Active':
      default:
        return AppColors.primary;
    }
  }

  /// Returns an icon associated with the given status filter label.
  IconData _statusChipIcon(String status) {
    switch (status) {
      case 'Unclaimed':
        return Icons.timer_off_outlined;
      case 'Claimed':
        return Icons.assignment_turned_in_outlined;
      case 'All Active':
      default:
        return Icons.check_circle_outline;
    }
  }
}
