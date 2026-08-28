import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: AppStyles.borderRadiusMd,
        border: border ??
            Border.all(
              color: AppColors.divider.withValues(alpha: 0.8),
              width: 1,
            ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyles.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppStyles.borderRadiusMd,
          child: Padding(
            padding: padding ?? AppStyles.paddingCard,
            child: child,
          ),
        ),
      ),
    );
  }
}
