import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'notification_navigation.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  ref
                      .read(repositoryProvider)
                      .markAllNotificationsAsRead(currentUser?.uid ?? 'guest');
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Notifications Yet',
              description: 'You will receive updates when items are reported, matches are found, or claims change.',
              icon: Icons.notifications_off_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = list[index];

              IconData icon = Icons.notifications_rounded;
              Color iconColor = AppColors.primary;

              if (notif.type == 'COMMON') {
                if (notif.itemType == 'LOST') {
                  icon = Icons.search_rounded;
                  iconColor = AppColors.warning;
                } else if (notif.itemType == 'FOUND') {
                  icon = Icons.check_circle_outline_rounded;
                  iconColor = AppColors.secondary;
                } else {
                  icon = Icons.campaign_rounded;
                  iconColor = AppColors.primary;
                }
              } else if (notif.type == 'POTENTIAL_MATCH') {
                icon = Icons.auto_awesome_rounded;
                iconColor = AppColors.accent;
              } else if (notif.type == 'CLAIM_SUBMITTED') {
                icon = Icons.assignment_outlined;
                iconColor = AppColors.primary;
              } else if (notif.type == 'CLAIM_APPROVED') {
                icon = Icons.check_circle_rounded;
                iconColor = AppColors.secondary;
              }

              final isUnread = !notif.isRead;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (notif.type == 'POTENTIAL_MATCH' && notif.targetId.isNotEmpty) {
                      openMatchedFoundItem(
                        context,
                        ref,
                        notificationId: notif.id,
                        foundItemId: notif.targetId,
                      );
                    } else if (isUnread) {
                      ref.read(repositoryProvider).markNotificationAsRead(notif.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: isUnread ? AppColors.primary : AppColors.divider,
                          width: isUnread ? 4 : 1,
                        ),
                        top: BorderSide(color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
                        right: BorderSide(color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
                        bottom: BorderSide(color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
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
                                        fontSize: 15,
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormatter.relativeTime(notif.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading notifications: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}
