import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _db = FirestoreService();

  User? _user;
  bool _loading = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isSignedIn => _user != null;
  String? get error => _error;

  late final StreamSubscription<User?> _authSub;

  AuthProvider() {
    _authSub = _auth.authStateChanges().listen((user) {
      _user = user;
      _loading = false;
      if (user != null) {
        _db.updateLastLogin(user.uid);
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _error = null;
    try {
      final gUser = await _googleSignIn.signIn();
      if (gUser == null) return false;
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _error = null;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _mapError(String code) {
    const messages = {
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password.',
      'invalid-email': 'Please enter a valid email address.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'invalid-credential': 'Incorrect email or password.',
      'email-already-in-use': 'An account already exists with this email.',
      'weak-password': 'Password is too weak. Use at least 6 characters.',
    };
    return messages[code] ?? 'Authentication failed. Please try again.';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
