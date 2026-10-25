import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utilities for standard date and time formatting throughout ReClaim
abstract class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _fullDateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _fullDateTimeFormat.format(date);
  }

  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Calculates the days remaining before reaching the 30-day unclaimed deadline.
  /// Uses [createdAt] and the configured [AppConstants.unclaimedAfterDays].
  /// Returns 0 if the deadline has passed.
  static int daysRemainingUntilUnclaimed(DateTime createdAt, [DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final deadline = createdAt.add(
      const Duration(days: AppConstants.unclaimedAfterDays),
    );
    if (!currentTime.isBefore(deadline)) {
      return 0;
    }
    final difference = deadline.difference(currentTime);
    final days = (difference.inSeconds / 86400.0).ceil();
    if (days <= 0) return 0;
    if (days > AppConstants.unclaimedAfterDays) {
      return AppConstants.unclaimedAfterDays;
    }
    return days;
  }

  /// Returns the unclaimed deadline label (e.g., "18 days left" or "Unclaimed period expired").
  /// Returns null for statuses where the countdown is not applicable (CLAIMED, RETURNED, CLOSED).
  static String? getUnclaimedCountdownLabel(
    DateTime createdAt,
    String status, [
    DateTime? now,
  ]) {
    final upper = status.toUpperCase();

    // Claimed, returned, and closed reports must not show an active countdown
    if (upper == AppConstants.statusClaimed ||
        upper == AppConstants.statusReturned ||
        upper == AppConstants.statusClosed) {
      return null;
    }

    if (upper == AppConstants.statusUnclaimed) {
      return 'Unclaimed period expired';
    }

    if (upper == AppConstants.statusActive) {
      final days = daysRemainingUntilUnclaimed(createdAt, now);
      if (days <= 0) {
        return 'Unclaimed period expired';
      }
      return '$days ${days == 1 ? 'day' : 'days'} left';
    }

    return null;
  }
}