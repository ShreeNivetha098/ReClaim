import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'firebase_service.dart';

/// Stores item photos as raw bytes in Firestore (`itemImages` collection).
///
/// Firebase Storage needs the paid Blaze plan, so photos live in Firestore
/// instead. An item's `imageUrl` holds a reference such as
/// `firestore:itemImages/<id>`; plain `http(s)` URLs from older records
/// still work and are loaded from the network.
class ImageStoreService {
  static const collection = 'itemImages';
  static const refPrefix = 'firestore:$collection/';

  /// Firestore documents are limited to 1 MiB, so leave room for metadata.
  static const maxBytes = 900 * 1024;

  /// Settings passed to image_picker so photos stay well under [maxBytes].
  static const pickerMaxDimension = 1024.0;
  static const pickerQuality = 70;

  static const _uuid = Uuid();
  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _pending = {};

  static bool isStoredRef(String? imageUrl) =>
      imageUrl != null && imageUrl.startsWith(refPrefix);

  static String _docId(String ref) => ref.substring(refPrefix.length);

  /// Saves [bytes] and returns the reference to put in an item's `imageUrl`.
  static Future<String> save(Uint8List bytes, {required String uploaderId}) async {
    if (bytes.length > maxBytes) {
      throw ArgumentError(
        'Photo is too large (${(bytes.length / 1024).round()} KB). '
        'Please choose a smaller photo.',
      );
    }

    final id = _uuid.v4();
    await FirebaseService.firestore.collection(collection).doc(id).set({
      'data': Blob(bytes),
      'uploaderId': uploaderId,
      'sizeBytes': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _cache['$refPrefix$id'] = bytes;
    return '$refPrefix$id';
  }

  /// Deletes a stored photo. Failures are only logged: a leftover photo is harmless.
  static Future<void> delete(String? imageUrl) async {
    if (!isStoredRef(imageUrl)) return;
    _cache.remove(imageUrl);
    if (!FirebaseService.isInitialized) return;
    try {
      await FirebaseService.firestore.collection(collection).doc(_docId(imageUrl!)).delete();
    } catch (e) {
      debugPrint('ImageStoreService.delete error: $e');
    }
  }

  /// Returns already-loaded bytes without a network call.
  static Uint8List? cached(String ref) => _cache[ref];

  /// Loads the bytes for a `firestore:` reference, or null if it is missing.
  static Future<Uint8List?> load(String ref) {
    final cached = _cache[ref];
    if (cached != null) return Future.value(cached);
    // Share one read between widgets that ask for the same photo at once.
    return _pending.putIfAbsent(ref, () => _fetch(ref).whenComplete(() => _pending.remove(ref)));
  }

  static Future<Uint8List?> _fetch(String ref) async {
    try {
      final snap = await FirebaseService.firestore.collection(collection).doc(_docId(ref)).get();
      final blob = snap.data()?['data'];
      if (blob is! Blob) return null;
      _cache[ref] = blob.bytes;
      return blob.bytes;
    } catch (e) {
      debugPrint('ImageStoreService.load error: $e');
      return null;
    }
  }
}
