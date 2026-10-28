import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static bool _isFirebaseInitialized = false;

  static bool get isInitialized => _isFirebaseInitialized;

  /// Web config is passed at build time so it never has to be committed:
  /// `flutter build web --dart-define-from-file=firebase_web.json`.
  static const _webOptions = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_WEB_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET'),
  );

  /// Local testing only: `--dart-define=USE_FIREBASE_EMULATORS=true` points the
  /// app at the Auth and Firestore emulators instead of the live project.
  static const _useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
        return;
      }
      if (kIsWeb) {
        if (_webOptions.apiKey.isEmpty) {
          throw StateError('Missing web config. Build with --dart-define-from-file=firebase_web.json');
        }
        await Firebase.initializeApp(options: _webOptions);
        if (_useEmulators) {
          await auth.useAuthEmulator('localhost', 9099);
          firestore.useFirestoreEmulator('localhost', 8080);
        }
        // The browser restores a saved login asynchronously; wait for it so
        // reloading the admin dashboard does not sign the admin out.
        await auth.authStateChanges().first;
      } else {
        // iOS reads its configuration from ios/GoogleService-Info.plist.
        await Firebase.initializeApp();
        if (_useEmulators) {
          await auth.useAuthEmulator('localhost', 9099);
          firestore.useFirestoreEmulator('localhost', 8080);
        }
      }
      _isFirebaseInitialized = true;
      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('Firebase initialization warning: $e');
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
