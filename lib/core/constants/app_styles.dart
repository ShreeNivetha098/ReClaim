import 'package:flutter/material.dart';

/// ReClaim Spacing & Design Constants
abstract class AppStyles {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // Padding
  static const EdgeInsets paddingPage = EdgeInsets.all(md);
  static const EdgeInsets paddingCard = EdgeInsets.all(md);

  // Card Elevation
  static const double cardElevation = 0.0; // Clean flat M3 look with subtle border
}
