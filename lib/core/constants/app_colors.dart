import 'package:flutter/material.dart';

/// ReClaim colour palette: soft and friendly.
/// Indigo-violet brand, teal for found items, coral for lost items,
/// on a warm lavender-white background.
abstract class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF5B5BD6); // Soft indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF8B8CF2);

  static const Color secondary = Color(0xFF14B8A6); // Teal
  static const Color secondaryDark = Color(0xFF0F9488);
  static const Color secondaryLight = Color(0xFF5EEAD4);

  static const Color accent = Color(0xFFF59E0B); // Warm amber (matches)
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFCD34D);

  /// Lost items are coral, found items are teal, everywhere in the app.
  static const Color lost = Color(0xFFFF7A59);
  static const Color found = secondary;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient lostGradient = LinearGradient(
    colors: [Color(0xFFFF9A76), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient foundGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF0EA5A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background & Neutral Colors
  static const Color background = Color(0xFFF6F5FB); // Warm lavender-white
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFECEAF4);
  static const Color inputFill = Color(0xFFF1F0F8);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1B3A); // Deep ink
  static const Color textSecondary = Color(0xFF5C5A75);
  static const Color textMuted = Color(0xFF9B99B3);

  // System Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF6366F1);

  // Soft shadow tint used by cards and floating elements
  static const Color shadow = Color(0xFF5B5BD6);

  // Status Chip Colors
  static const Color statusActiveBg = Color(0xFFE6E6FB);
  static const Color statusActiveText = Color(0xFF4338CA);

  static const Color statusMatchedBg = Color(0xFFFEF3C7);
  static const Color statusMatchedText = Color(0xFF92400E);

  static const Color statusClaimedBg = Color(0xFFEDE9FE);
  static const Color statusClaimedText = Color(0xFF6D28D9);

  static const Color statusUnclaimedBg = Color(0xFFFFEDE6);
  static const Color statusUnclaimedText = Color(0xFFC2410C);

  static const Color statusReturnedBg = Color(0xFFD5F5EF);
  static const Color statusReturnedText = Color(0xFF0F766E);

  static const Color statusClosedBg = Color(0xFFF1F0F6);
  static const Color statusClosedText = Color(0xFF5C5A75);
}
