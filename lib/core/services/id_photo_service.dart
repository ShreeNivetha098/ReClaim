import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'image_store_service.dart';

/// Stores the college ID card photo a user submits for verification.
///
/// Kept apart from item photos on purpose: `idPhotos/{uid}` can only be read
/// by that user and admins, and the photo is deleted as soon as an admin
/// verifies or rejects it, so no ID images are kept long-term.
class IdPhotoService {
  static const collection = 'idPhotos';

  /// In-memory store used when Firebase is not configured (tests, demo mode).
  static final Map<String, Uint8List> _mockPhotos = {};

  static Future<void> save(String uid, Uint8List bytes) async {
    if (bytes.length > ImageStoreService.maxBytes) {
      throw ArgumentError(
        'Photo is too large (${(bytes.length / 1024).round()} KB). '
        'Please choose a smaller photo.',
      );
    }
    if (!FirebaseService.isInitialized) {
      _mockPhotos[uid] = bytes;
      return;
    }
    await FirebaseService.firestore.collection(collection).doc(uid).set({
      'data': Blob(bytes),
      'uploaderId': uid,
      'sizeBytes': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Uint8List?> load(String uid) async {
    if (!FirebaseService.isInitialized) return _mockPhotos[uid];
    try {
      final snap = await FirebaseService.firestore.collection(collection).doc(uid).get();
      final blob = snap.data()?['data'];
      return blob is Blob ? blob.bytes : null;
    } catch (e) {
      debugPrint('IdPhotoService.load error: $e');
      return null;
    }
  }

  static Future<void> delete(String uid) async {
    if (!FirebaseService.isInitialized) {
      _mockPhotos.remove(uid);
      return;
    }
    await FirebaseService.firestore.collection(collection).doc(uid).delete();
  }

  @visibleForTesting
  static bool hasMockPhoto(String uid) => _mockPhotos.containsKey(uid);
}
