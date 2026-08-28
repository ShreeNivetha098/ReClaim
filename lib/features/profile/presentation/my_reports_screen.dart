import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../item_details/presentation/item_details_screen.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final lostItemsAsync = ref.watch(lostItemsProvider);
    final foundItemsAsync = ref.watch(foundItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reported Items'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Lost Reports'),
            Tab(text: 'My Found Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Lost Reports
          lostItemsAsync.when(
            data: (items) {
              final currentUid = FirebaseService.isInitialized
                  ? FirebaseService.auth.currentUser?.uid
                  : (user?.uid ?? 'guest');
              final myLost = items.where((i) => i.ownerId == currentUid).toList();

              if (myLost.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Lost Reports Found',
                  description: 'You have not submitted any lost item reports.',
                  icon: Icons.search_off_rounded,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myLost.length,
                itemBuilder: (context, index) {
                  final item = myLost[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ItemCard(
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
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error loading reports: $err'),
          ),

          // My Found Reports
          foundItemsAsync.when(
            data: (items) {
              final myFound = items.where((i) => i.finderId == (user?.uid ?? 'guest')).toList();

              if (myFound.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Found Reports',
                  description: 'You have not submitted any found item reports.',
                  icon: Icons.inventory_2_outlined,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myFound.length,
                itemBuilder: (context, index) {
                  final item = myFound[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ItemCard(
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
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error loading reports: $err'),
          ),
        ],
      ),
    );
  }
}
