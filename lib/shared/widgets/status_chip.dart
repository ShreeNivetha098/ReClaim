import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Rounded pill showing a report's status with a coloured dot.
class StatusChip extends StatelessWidget {
  final String status;

  /// Smaller version for tight spaces such as item cards.
  final bool compact;

  const StatusChip({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final upperStatus = status.toUpperCase();
    final (Color bgColor, Color textColor) = switch (upperStatus) {
      'ACTIVE' => (AppColors.statusActiveBg, AppColors.statusActiveText),
      'MATCHED' => (AppColors.statusMatchedBg, AppColors.statusMatchedText),
      'CLAIMED' => (AppColors.statusClaimedBg, AppColors.statusClaimedText),
      'UNCLAIMED' => (AppColors.statusUnclaimedBg, AppColors.statusUnclaimedText),
      'RETURNED' => (AppColors.statusReturnedBg, AppColors.statusReturnedText),
      _ => (AppColors.statusClosedBg, AppColors.statusClosedText),
    };

    final label = upperStatus.isEmpty
        ? ''
        : upperStatus[0] + upperStatus.substring(1).toLowerCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
