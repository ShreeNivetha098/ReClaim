import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/animations.dart';
import '../../notifications/presentation/notification_navigation.dart';
import '../../home/presentation/home_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../lost_items/presentation/report_lost_item_screen.dart';
import '../../found_items/presentation/report_found_item_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _selectedIndex;

  /// Notification IDs already on screen; null until the first snapshot so
  /// older notifications do not raise banners when the app opens.
  Set<String>? _seenNotificationIds;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _setUpMatchBanners();
  }

  @override
  void dispose() {
    LocalNotificationService.onTap = null;
    super.dispose();
  }

  Future<void> _setUpMatchBanners() async {
    LocalNotificationService.onTap = (payload) {
      if (mounted) openFoundItemPayload(context, ref, payload);
    };
    final launchPayload = await LocalNotificationService.initialize();
    if (launchPayload != null && mounted) {
      openFoundItemPayload(context, ref, launchPayload);
    }
  }

  /// Raises an iOS banner for each new match or claim-decision notification.
  void _onNotificationsChanged(List<NotificationModel> notifications) {
    final seen = _seenNotificationIds;
    _seenNotificationIds = notifications.map((n) => n.id).toSet();
    if (seen == null) return;

    for (final notif in notifications) {
      if (seen.contains(notif.id) || notif.isRead || !foundItemNotificationTypes.contains(notif.type)) {
        continue;
      }
      LocalNotificationService.show(
        id: notif.id,
        title: notif.title,
        body: notif.body,
        payload: foundItemPayload(notif.id, notif.targetId),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showReportOptionsSheet(context);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showReportOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        void open(Widget screen) {
          Navigator.pop(sheetContext);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happened?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick one and we will guide you through it.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ReportChoice(
                        gradient: AppColors.lostGradient,
                        icon: Icons.search_rounded,
                        title: 'I lost\nsomething',
                        subtitle: 'Get alerted when it turns up',
                        onTap: () => open(const ReportLostItemScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ReportChoice(
                        gradient: AppColors.foundGradient,
                        icon: Icons.volunteer_activism_rounded,
                        title: 'I found\nsomething',
                        subtitle: 'Help it get back home',
                        onTap: () => open(const ReportFoundItemScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsProvider, (_, next) {
      next.whenData(_onNotificationsChanged);
    });

    final screens = [
      HomeScreen(
        onNavigateToSearch: () => setState(() => _selectedIndex = 1),
        onNavigateToNotifications: () => setState(() => _selectedIndex = 3),
      ),
      const SearchScreen(),
      const SizedBox(), // Report tab triggers bottom sheet modal
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey(_selectedIndex), child: screens[_selectedIndex]),
      ),
      bottomNavigationBar: _FloatingTabBar(
        selectedIndex: _selectedIndex,
        unreadCount: unreadNotifsCount,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _ReportChoice extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportChoice({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppStyles.borderRadiusLg,
          boxShadow: AppStyles.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded white tab bar that floats above the content, with a raised
/// gradient "report" button in the middle.
class _FloatingTabBar extends StatelessWidget {
  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _tab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _tab(1, Icons.search_rounded, Icons.manage_search_rounded, 'Search'),
              Expanded(
                child: Center(
                  child: PressableScale(
                    onTap: () => onTap(2),
                    pressedScale: 0.9,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppStyles.floatingShadow,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              _tab(3, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Alerts', badge: unreadCount),
              _tab(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final selected = selectedIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;
    Widget iconWidget = Icon(selected ? activeIcon : icon, color: color, size: 25);
    if (badge > 0) iconWidget = Badge.count(count: badge, backgroundColor: AppColors.lost, child: iconWidget);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: PressableScale(
          onTap: () => onTap(index),
          pressedScale: 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.statusActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: iconWidget,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
