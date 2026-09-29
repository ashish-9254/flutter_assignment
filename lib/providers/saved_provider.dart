import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/photo.dart';
import '../services/auth_service.dart';
import '../services/saved_service.dart';

/// The single source of truth for "which photos has this user saved".
///
/// Every screen that shows a save button, the Saved tab, and the profile
/// count all read from this one object, so a change made anywhere shows up
/// everywhere immediately.
///
/// It follows the signed-in account: when the uid changes (login / logout /
/// a different account) it drops the old list and subscribes to the new
/// user's Firestore collection.
class SavedProvider extends ChangeNotifier {
  SavedProvider({AuthService? authService, SavedService? savedService})
      : _authService = authService ?? AuthService(),
        _savedService = savedService ?? SavedService() {
    _authSub = _authService.uidChanges.listen(_onUidChanged);
  }

  final AuthService _authService;
  final SavedService _savedService;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<List<Photo>>? _savedSub;

  String? _uid;
  List<Photo> _photos = const [];
  Set<int> _ids = <int>{};
  bool _isLoading = false;
  String? _error;

  List<Photo> get photos => _photos;
  int get count => _photos.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isSaved(int photoId) => _ids.contains(photoId);

  void _onUidChanged(String? uid) {
    _uid = uid;
    _savedSub?.cancel();
    _savedSub = null;
    _photos = const [];
    _ids = <int>{};
    _error = null;

    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _savedSub = _savedService.watchSaved(uid).listen(
          (photos) {
        _photos = photos;
        _ids = photos.map((p) => p.id).toSet();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _error = 'Could not load your saved photos.';
        notifyListeners();
      },
    );
  }

  /// Re-subscribes after a load error (used by the Saved screen's Retry).
  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _savedSub?.cancel();
    _subscribe(uid);
  }

  /// Saves the photo if it isn't saved, removes it if it is.
  ///
  /// The local list is updated first so the UI reacts instantly, then the
  /// change is written to Firestore. If the write fails the change is rolled
  /// back and the error is re-thrown so the caller can tell the user.
  Future<void> toggle(Photo photo) async {
    final uid = _uid;
    if (uid == null) return;

    final wasSaved = _ids.contains(photo.id);
    final previousPhotos = _photos;
    final previousIds = _ids;

    if (wasSaved) {
      _photos = _photos.where((p) => p.id != photo.id).toList();
      _ids = {..._ids}..remove(photo.id);
    } else {
      _photos = [photo, ..._photos];
      _ids = {..._ids, photo.id};
    }
    notifyListeners();

    try {
      if (wasSaved) {
        await _savedService.remove(uid, photo.id);
      } else {
        await _savedService.add(uid, photo);
      }
    } catch (_) {
      _photos = previousPhotos;
      _ids = previousIds;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _savedSub?.cancel();
    super.dispose();
  }
}