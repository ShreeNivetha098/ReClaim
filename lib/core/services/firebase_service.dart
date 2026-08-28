import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static bool _isFirebaseInitialized = false;

  static bool get isInitialized => _isFirebaseInitialized;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
        return;
      }
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('Firebase initialization warning: $e');
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
}
