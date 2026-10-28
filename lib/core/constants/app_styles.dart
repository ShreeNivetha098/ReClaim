import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ReClaim Spacing & Design Constants
abstract class AppStyles {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius: generous, rounded corners for a soft look
  static const double radiusSm = 10.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // Padding
  static const EdgeInsets paddingPage = EdgeInsets.all(md);
  static const EdgeInsets paddingCard = EdgeInsets.all(md);

  // Card Elevation (shadows are drawn with [softShadow] instead)
  static const double cardElevation = 0.0;

  /// Soft, tinted shadow for cards.
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Stronger shadow for floating elements such as the report button.
  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
