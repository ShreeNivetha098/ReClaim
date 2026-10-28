import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'animations.dart';

enum CustomButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54.0,
  });

  bool get _isFilled => type == CustomButtonType.primary || type == CustomButtonType.secondary;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final foreground = _isFilled ? Colors.white : AppColors.primary;

    final Widget label = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          );

    final BoxDecoration decoration = switch (type) {
      CustomButtonType.primary => BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppStyles.borderRadiusMd,
          boxShadow: isEnabled ? AppStyles.floatingShadow : null,
        ),
      CustomButtonType.secondary => BoxDecoration(
          gradient: AppColors.foundGradient,
          borderRadius: AppStyles.borderRadiusMd,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
      CustomButtonType.outlined => BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.borderRadiusMd,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
      CustomButtonType.text => BoxDecoration(borderRadius: AppStyles.borderRadiusMd),
    };

    return PressableScale(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isEnabled || isLoading ? 1 : 0.5,
        child: Container(
          width: width ?? double.infinity,
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: decoration,
          child: label,
        ),
      ),
    );
  }
}
