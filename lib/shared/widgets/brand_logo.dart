import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// ReClaim app mark: a gradient rounded square with a search-in-box icon.
/// [onGradient] draws a white version for use on gradient backgrounds.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool onGradient;

  const BrandLogo({super.key, this.size = 72, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onGradient ? null : AppColors.brandGradient,
        color: onGradient ? Colors.white : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: (onGradient ? Colors.black : AppColors.shadow).withValues(alpha: 0.2),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.travel_explore_rounded,
        size: size * 0.52,
        color: onGradient ? AppColors.primary : Colors.white,
      ),
    );
  }
}
