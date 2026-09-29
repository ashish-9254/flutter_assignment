import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/photo.dart';

/// Reads and writes a user's saved photos in Firestore.
///
/// Layout:  users/{uid}/saved/{photoId}
///
/// Keying everything under the uid is what gives each account its own list.
class SavedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('saved');
  }

  /// Live list, newest first. Firestore also emits immediately for local
  /// writes (before the server confirms), which is why saving feels instant.
  Stream<List<Photo>> watchSaved(String uid) {
    return _collection(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final photos = <Photo>[];
      for (final doc in snapshot.docs) {
        try {
          photos.add(Photo.fromSavedMap(doc.data()));
        } catch (_) {
          // Skip a malformed document instead of breaking the whole list.
        }
      }
      return photos;
    });
  }

  Future<void> add(String uid, Photo photo) {
    return _collection(uid).doc(photo.id.toString()).set({
      ...photo.toSavedMap(),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> remove(String uid, int photoId) {
    return _collection(uid).doc(photoId.toString()).delete();
  }
}