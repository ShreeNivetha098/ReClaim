import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows iOS notification banners on this device.
///
/// Remote push (APNs) needs a paid Apple Developer account and a server, so
/// instead the app raises a local banner when its Firestore listener receives
/// a new notification. Banners therefore appear while the app is open or when
/// the user returns to it, not while it has been closed for a long time.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Called with a banner's payload when the user taps it.
  static void Function(String payload)? onTap;

  /// Asks for notification permission (first time only) and registers the
  /// tap handler. Returns the payload of the banner that launched the app, if any.
  static Future<String?> initialize() async {
    if (_initialized) return null;
    // The screenshot tour (tool/screen_tour.py) skips the permission prompt,
    // which would otherwise cover every screenshot.
    if (const bool.fromEnvironment('SCREEN_TOUR')) return null;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(iOS: DarwinInitializationSettings()),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) onTap?.call(payload);
        },
      );
      _initialized = true;

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        return launch!.notificationResponse?.payload;
      }
    } catch (e) {
      // Not available in widget tests or on unsupported platforms.
      debugPrint('LocalNotificationService.initialize: $e');
    }
    return null;
  }

  static Future<void> show({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: id.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(iOS: DarwinNotificationDetails()),
        payload: payload,
      );
    } catch (e) {
      debugPrint('LocalNotificationService.show: $e');
    }
  }
}
