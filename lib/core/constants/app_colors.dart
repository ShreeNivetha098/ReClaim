import 'package:flutter/material.dart';

/// ReClaim Color Palette
/// Consistent Material 3 Color tokens for ReClaim application.
abstract class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  static const Color accent = Color(0xFFF59E0B); // Amber / Warm Yellow
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Background & Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // System Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Status Chip Colors
  static const Color statusActiveBg = Color(0xFFDBEAFE);
  static const Color statusActiveText = Color(0xFF1E40AF);

  static const Color statusMatchedBg = Color(0xFFFEF3C7);
  static const Color statusMatchedText = Color(0xFF92400E);

  static const Color statusClaimedBg = Color(0xFFE0E7FF);
  static const Color statusClaimedText = Color(0xFF3730A3);

  static const Color statusReturnedBg = Color(0xFFD1FAE5);
  static const Color statusReturnedText = Color(0xFF065F46);

  static const Color statusClosedBg = Color(0xFFF1F5F9);
  static const Color statusClosedText = Color(0xFF475569);
}
