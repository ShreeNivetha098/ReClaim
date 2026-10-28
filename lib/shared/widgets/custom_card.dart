import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'animations.dart';

/// Rounded white card with a soft shadow. Tappable cards shrink when pressed.
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
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: AppStyles.borderRadiusLg,
        border: border,
        boxShadow: AppStyles.softShadow,
      ),
      child: Padding(
        padding: padding ?? AppStyles.paddingCard,
        child: child,
      ),
    );
    return onTap == null ? card : PressableScale(onTap: onTap, child: card);
  }
}
