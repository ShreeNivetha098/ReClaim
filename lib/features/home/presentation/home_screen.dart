import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/models/match_result_model.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/category_style.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/item_card.dart';
import '../../lost_items/presentation/report_lost_item_screen.dart';
import '../../found_items/presentation/report_found_item_screen.dart';
import '../../item_details/presentation/item_details_screen.dart';
import '../../matching/presentation/potential_matches_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToNotifications;

  const HomeScreen({
    super.key,
    required this.onNavigateToSearch,
    required this.onNavigateToNotifications,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showLost = true;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _searchCategory(String category) {
    ref.read(categoryFilterProvider.notifier).state = category;
    widget.onNavigateToSearch();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final lostItemsAsync = ref.watch(activeLostItemsProvider);
    final foundItemsAsync = ref.watch(activeFoundItemsProvider);
    final allLostItemsAsync = ref.watch(lostItemsProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);

    final firstName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : 'there';

    return Scaffold(
      body: StatusBarScrim(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(lostItemsProvider.notifier).loadLostItems(),
              ref.read(foundItemsProvider.notifier).loadFoundItems(),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                greeting: _greeting,
                name: firstName,
                initial: firstName.isNotEmpty
                    ? firstName[0].toUpperCase()
                    : 'U',
                isVerified: user?.isVerified ?? false,
                unreadCount: unreadNotifsCount,
                onNotifications: widget.onNavigateToNotifications,
                onSearch: widget.onNavigateToSearch,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick actions
                    FadeSlideIn(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              gradient: AppColors.lostGradient,
                              icon: Icons.search_rounded,
                              title: 'I lost\nsomething',
                              onTap: () => _open(const ReportLostItemScreen()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionTile(
                              gradient: AppColors.foundGradient,
                              icon: Icons.volunteer_activism_rounded,
                              title: 'I found\nsomething',
                              onTap: () => _open(const ReportFoundItemScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildPotentialMatchBanner(allLostItemsAsync),

                    const SizedBox(height: 26),
                    const _SectionTitle('Browse by category'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: itemCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = itemCategories[index];
                          return FadeSlideIn(
                            index: index,
                            child: _CategoryBubble(
                              label: category,
                              icon: categoryIcon(category),
                              onTap: () => _searchCategory(category),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle('Recently reported'),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToSearch,
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LostFoundToggle(
                      showLost: _showLost,
                      onChanged: (value) => setState(() => _showLost = value),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showLost
                          ? KeyedSubtree(
                              key: const ValueKey('lost'),
                              child: _buildLostGrid(lostItemsAsync),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('found'),
                              child: _buildFoundGrid(foundItemsAsync),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLostGrid(AsyncValue<List<LostItemModel>> async) {
    return async.when(
      data: (items) => _grid(
        itemCount: items.take(6).length,
        emptyTitle: 'Nothing lost right now',
        emptyText: 'Lost reports from your campus will show up here.',
        builder: (index) {
          final item = items[index];
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
            onTap: () => _open(ItemDetailsScreen(lostItem: item)),
          );
        },
      ),
      loading: () => const _GridLoading(),
      error: (err, _) => Text('Could not load lost items: $err'),
    );
  }

  Widget _buildFoundGrid(AsyncValue<List<FoundItemModel>> async) {
    return async.when(
      data: (items) => _grid(
        itemCount: items.take(6).length,
        emptyTitle: 'Nothing found yet',
        emptyText: 'Items people hand in will show up here.',
        builder: (index) {
          final item = items[index];
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
            onTap: () => _open(ItemDetailsScreen(foundItem: item)),
          );
        },
      ),
      loading: () => const _GridLoading(),
      error: (err, _) => Text('Could not load found items: $err'),
    );
  }

  Widget _grid({
    required int itemCount,
    required String emptyTitle,
    required String emptyText,
    required Widget Function(int index) builder,
  }) {
    if (itemCount == 0) {
      return EmptyStateWidget(
        title: emptyTitle,
        description: emptyText,
        icon: Icons.inbox_rounded,
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: ItemCard.gridHeight,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          FadeSlideIn(index: index, child: builder(index)),
    );
  }

  Widget _buildPotentialMatchBanner(
    AsyncValue<List<LostItemModel>> lostItemsAsync,
  ) {
    return lostItemsAsync.maybeWhen(
      data: (lostItems) {
        // Only the signed-in user's own open lost reports.
        final uid = ref.watch(currentUserProvider)?.uid;
        final myOpenLost = lostItems.where((item) {
          final status = item.status.toUpperCase();
          return item.ownerId == uid &&
              (status == 'ACTIVE' || status == 'MATCHED');
        });

        // Best match across all of them.
        MatchResultModel? topMatch;
        for (final lost in myOpenLost) {
          final matches = ref.watch(potentialMatchesProvider(lost));
          if (matches.isNotEmpty &&
              (topMatch == null ||
                  matches.first.matchPercentage > topMatch.matchPercentage)) {
            topMatch = matches.first;
          }
        }
        if (topMatch == null) return const SizedBox.shrink();
        final match = topMatch;

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: FadeSlideIn(
            child: PressableScale(
              onTap: () =>
                  _open(PotentialMatchesScreen(lostItem: match.lostItem)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4D6), Color(0xFFFFE7C2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppStyles.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: match.matchPercentage / 100,
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 5,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.white,
                                  color: AppColors.accentDark,
                                ),
                          ),
                          Text(
                            '${match.matchPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: AppColors.accentDark,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Possible match!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${match.foundItem.itemName}" looks like your ${match.lostItem.itemName}.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final String initial;
  final bool isVerified;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;

  const _Header({
    required this.greeting,
    required this.name,
    required this.initial,
    required this.isVerified,
    required this.unreadCount,
    required this.onNotifications,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Soft decorative circles
          Positioned(top: -40, right: -30, child: _bubble(160, 0.10)),
          Positioned(bottom: -50, left: -40, child: _bubble(140, 0.08)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      PressableScale(
                        onTap: onNotifications,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Badge(
                            isLabelVisible: unreadCount > 0,
                            label: Text('$unreadCount'),
                            backgroundColor: AppColors.lost,
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Lost something on campus?\nLet\'s get it back.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PressableScale(
                    onTap: onSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search wallets, keys, ID cards…',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppStyles.borderRadiusLg,
          boxShadow: AppStyles.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryBubble({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppStyles.softShadow,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LostFoundToggle extends StatelessWidget {
  final bool showLost;
  final ValueChanged<bool> onChanged;

  const _LostFoundToggle({required this.showLost, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: showLost ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppStyles.softShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _option(
                'Recently lost',
                AppColors.lost,
                selected: showLost,
                onTap: () => onChanged(true),
              ),
              _option(
                'Recently found',
                AppColors.found,
                selected: !showLost,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(
    String label,
    Color color, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _GridLoading extends StatelessWidget {
  const _GridLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
