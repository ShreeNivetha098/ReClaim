/// ReClaim App Constants
/// Centralized configuration constants for application behavior.
abstract class AppConstants {
  /// Number of days after which an ACTIVE item is automatically
  /// reclassified as UNCLAIMED. Change this single value to adjust
  /// the threshold across the entire application.
  static const int unclaimedAfterDays = 30;

  /// Known item status values used throughout the application.
  static const String statusActive = 'ACTIVE';
  static const String statusMatched = 'MATCHED';
  static const String statusClaimed = 'CLAIMED';
  static const String statusUnclaimed = 'UNCLAIMED';
  static const String statusReturned = 'RETURNED';
  static const String statusClosed = 'CLOSED';
}
