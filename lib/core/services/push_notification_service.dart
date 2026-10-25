
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  debugPrint('FCM background message received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _registeredUserId;
  static String? _currentToken;

  /// Initialize message listeners once Firebase is ready.
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.messageId}');
      debugPrint('FCM data: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint('User tapped an FCM notification.');
        debugPrint('FCM data: ${message.data}');
      },
    );

    // Show notification banners while the app is open on iOS.
    // Guarded with a timeout so an unresponsive native iOS channel cannot hang startup.
    try {
      await _messaging
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('PushNotificationService setForegroundNotificationPresentationOptions notice: $e');
    }

    try {
      final initialMessage = await _messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
      if (initialMessage != null) {
        debugPrint('App opened from an FCM notification.');
        debugPrint('FCM data: ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('PushNotificationService getInitialMessage notice: $e');
    }
  }

  /// Request permission and associate this device with a signed-in user.
  static Future<void> registerDeviceForUser(String userId) async {
    if (!FirebaseService.isInitialized || userId.isEmpty) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!authorized) {
        debugPrint('Push notification permission was not granted.');
        return;
      }

      // On Apple devices, wait until APNs has provided its token.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNs token is not ready yet. Retry registration later.');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is not available yet.');
        return;
      }

      await _saveToken(userId, token);
      _registeredUserId = userId;
      _currentToken = token;

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        (newToken) {
          _saveToken(userId, newToken).catchError((Object error) {
            debugPrint('FCM token refresh save failed: $error');
          });
          _currentToken = newToken;
        },
        onError: (Object error) {
          debugPrint('FCM token refresh error: $error');
        },
      );

      debugPrint('FCM device registration completed for user $userId.');
    } catch (e) {
      debugPrint('FCM device registration failed: $e');
    }
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseService.firestore
        .collection('users')
        .doc(userId)
        .set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove this device's token when the current user signs out.
  static Future<void> unregisterDevice() async {
    final userId = _registeredUserId;
    final token = _currentToken;

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    if (userId != null && token != null &&
        FirebaseService.isInitialized) {
      try {
        await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } catch (e) {
        debugPrint('Could not remove FCM token during logout: $e');
      }
    }

    _registeredUserId = null;
    _currentToken = null;
  }
}
