import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final upperStatus = status.toUpperCase();

    Color bgColor;
    Color textColor;

    switch (upperStatus) {
      case 'ACTIVE':
        bgColor = AppColors.statusActiveBg;
        textColor = AppColors.statusActiveText;
        break;
      case 'MATCHED':
        bgColor = AppColors.statusMatchedBg;
        textColor = AppColors.statusMatchedText;
        break;
      case 'CLAIMED':
        bgColor = AppColors.statusClaimedBg;
        textColor = AppColors.statusClaimedText;
        break;
      case 'RETURNED':
        bgColor = AppColors.statusReturnedBg;
        textColor = AppColors.statusReturnedText;
        break;
      case 'CLOSED':
      default:
        bgColor = AppColors.statusClosedBg;
        textColor = AppColors.statusClosedText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        upperStatus,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
