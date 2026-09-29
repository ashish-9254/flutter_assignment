import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth. Screens and providers talk to this class
/// so firebase_auth details stay in one place.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Emits the signed-in user's uid (or null) whenever it changes. The saved
  /// photos provider listens to this so each account gets its own list.
  Stream<String?> get uidChanges =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid).distinct();

  User? get currentUser => _firebaseAuth.currentUser;

  String? get currentEmail => _firebaseAuth.currentUser?.email;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() => _firebaseAuth.signOut();
}