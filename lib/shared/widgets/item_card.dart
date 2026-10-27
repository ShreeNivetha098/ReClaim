import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/date_formatter.dart';
import 'custom_card.dart';
import 'item_image.dart';
import 'status_chip.dart';

class ItemCard extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final DateTime date;
  final DateTime? createdAt;
  final String? imageUrl;
  final String status;
  final bool isLost;
  final double? matchPercentage;
  final String? reporterName;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    this.createdAt,
    this.imageUrl,
    required this.status,
    required this.isLost,
    this.matchPercentage,
    this.reporterName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCreatedAt = createdAt ?? date;
    final countdownLabel = DateFormatter.getUnclaimedCountdownLabel(effectiveCreatedAt, status);

    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Header Stack
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isLost
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppStyles.radiusMd),
                  ),
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppStyles.radiusMd),
                        ),
                        child: ItemImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context) => Container(
                            color: AppColors.divider.withValues(alpha: 0.3),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (context) => Icon(
                            isLost ? Icons.search_off : Icons.find_in_page,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          isLost ? Icons.search : Icons.inventory_2_outlined,
                          size: 44,
                          color: isLost ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
              ),

              // Lost vs Found Type Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLost ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLost ? 'LOST' : 'FOUND',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Status Chip
              Positioned(
                top: 8,
                right: 8,
                child: StatusChip(status: status),
              ),

              // Unclaimed Countdown / Deadline Badge
              if (countdownLabel != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: countdownLabel == 'Unclaimed period expired'
                          ? AppColors.statusUnclaimedText.withValues(alpha: 0.92)
                          : Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          countdownLabel == 'Unclaimed period expired'
                              ? Icons.timer_off_outlined
                              : Icons.hourglass_bottom_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          countdownLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Match Percentage Badge (if available)
              if (matchPercentage != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${matchPercentage!.toStringAsFixed(0)}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDate(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Reported by: ${reporterName != null && reporterName!.trim().isNotEmpty ? reporterName! : "Unknown user"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
