import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'notification_navigation.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  void _open(NotificationModel notif) {
    if (foundItemNotificationTypes.contains(notif.type) && notif.targetId.isNotEmpty) {
      openMatchedFoundItem(context, ref, notificationId: notif.id, foundItemId: notif.targetId);
    } else if (!notif.isRead) {
      ref.read(repositoryProvider).markNotificationAsRead(notif.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Text('Alerts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) {
              if (!list.any((n) => !n.isRead)) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () =>
                    ref.read(repositoryProvider).markAllNotificationsAsRead(currentUser?.uid ?? 'guest'),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (all) {
          final unreadCount = all.where((n) => !n.isRead).length;
          final list = _unreadOnly ? all.where((n) => !n.isRead).toList() : all;
          final today = DateTime.now();
          bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
          final todays = list.where((n) => isToday(n.createdAt)).toList();
          final earlier = list.where((n) => !isToday(n.createdAt)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _filterChip('All', !_unreadOnly, () => setState(() => _unreadOnly = false)),
                    const SizedBox(width: 8),
                    _filterChip(
                      unreadCount > 0 ? 'Unread · $unreadCount' : 'Unread',
                      _unreadOnly,
                      () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? EmptyStateWidget(
                        title: _unreadOnly ? 'You are all caught up' : 'No alerts yet',
                        description: _unreadOnly
                            ? 'New matches and claim updates will appear here.'
                            : 'You will hear from us when items are reported, matched or claimed.',
                        icon: _unreadOnly ? Icons.mark_email_read_rounded : Icons.notifications_none_rounded,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        children: [
                          if (todays.isNotEmpty) ...[
                            const _GroupLabel('Today'),
                            ..._cards(todays, 0),
                          ],
                          if (earlier.isNotEmpty) ...[
                            const _GroupLabel('Earlier'),
                            ..._cards(earlier, todays.length),
                          ],
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Swipe an alert to mark it as read',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Could not load alerts: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }

  List<Widget> _cards(List<NotificationModel> items, int offset) {
    return [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FadeSlideIn(
            index: offset + i,
            child: _NotificationCard(
              notif: items[i],
              onTap: () => _open(items[i]),
              onMarkRead: () => ref.read(repositoryProvider).markNotificationAsRead(items[i].id),
            ),
          ),
        ),
    ];
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _NotificationCard({required this.notif, required this.onTap, required this.onMarkRead});

  (IconData, Color) get _style {
    switch (notif.type) {
      case 'COMMON':
        if (notif.itemType == 'LOST') return (Icons.search_rounded, AppColors.lost);
        if (notif.itemType == 'FOUND') return (Icons.volunteer_activism_rounded, AppColors.found);
        return (Icons.campaign_rounded, AppColors.primary);
      case 'POTENTIAL_MATCH':
        return (Icons.auto_awesome_rounded, AppColors.accentDark);
      case 'CLAIM_SUBMITTED':
        return (Icons.assignment_rounded, AppColors.primary);
      case 'CLAIM_APPROVED':
        return (Icons.check_circle_rounded, AppColors.success);
      case 'CLAIM_REJECTED':
        return (Icons.cancel_rounded, AppColors.error);
      case 'VERIFICATION_APPROVED':
        return (Icons.verified_rounded, AppColors.success);
      case 'VERIFICATION_REJECTED':
        return (Icons.error_outline_rounded, AppColors.error);
      default:
        return (Icons.notifications_rounded, AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final isUnread = !notif.isRead;

    final card = PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.borderRadiusLg,
          boxShadow: isUnread ? AppStyles.softShadow : null,
          border: Border.all(color: isUnread ? color.withValues(alpha: 0.25) : AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        DateFormatter.relativeTime(notif.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isUnread) return card;

    // Swipe to mark as read; the card stays in the list.
    return Dismissible(
      key: ValueKey('notif-${notif.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onMarkRead();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: AppStyles.borderRadiusLg,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, color: AppColors.success),
            SizedBox(width: 6),
            Text('Mark read', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: card,
    );
  }
}
