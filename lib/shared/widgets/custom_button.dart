import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

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
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == CustomButtonType.outlined || type == CustomButtonType.text
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      child = Text(text);
    }

    Widget buttonWidget;

    switch (type) {
      case CustomButtonType.primary:
        buttonWidget = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusMd,
            ),
          ),
          child: child,
        );
        break;
      case CustomButtonType.secondary:
        buttonWidget = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusMd,
            ),
          ),
          child: child,
        );
        break;
      case CustomButtonType.outlined:
        buttonWidget = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusMd,
            ),
          ),
          child: child,
        );
        break;
      case CustomButtonType.text:
        buttonWidget = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusMd,
            ),
          ),
          child: child,
        );
        break;
    }

    return buttonWidget;
  }
}
