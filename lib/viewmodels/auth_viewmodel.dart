import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    SharedPreferences? prefs,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn,
       _prefs = prefs;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  final SharedPreferences? _prefs;

  User? get currentUser => _firebaseAuth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  
  bool _isLoading = false;
  bool _isDarkMode = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
      }
      _setError(errorMessage);
      return null;
    } catch (e) {
      _setError('Sign in failed: $e');
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Account creation failed: ${e.message}';
      }
      _setError(errorMessage);
      return null;
    } catch (e) {
      _setError('Account creation failed: $e');
      if (kDebugMode) {
        print('Create account error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // TODO: Fix GoogleSignIn API compatibility
      _setError('Google Sign-In temporarily disabled. Please use email/password.');
      return null;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final futures = <Future>[_firebaseAuth.signOut()];
      if (_googleSignIn != null) {
        futures.add(_googleSignIn!.signOut());
      }
      await Future.wait(futures);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Failed to send reset email. Please try again.');
      if (kDebugMode) {
        print('Password reset error: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize theme settings
  Future<void> initializeTheme() async {
    if (_prefs != null) {
      _isDarkMode = _prefs.getBool('dark_mode') ?? false;
      notifyListeners();
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    if (_prefs != null) {
      await _prefs.setBool('dark_mode', _isDarkMode);
    }
    notifyListeners();
  }

  /// Get user display name
  String get displayName {
    final user = currentUser;
    if (user == null) return 'User';
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    if (user.email != null) {
      return user.email!.split('@')[0];
    }
    
    return 'User';
  }

  /// Get user email
  String get userEmail {
    return currentUser?.email ?? '';
  }

  /// Get user photo URL
  String? get photoUrl {
    return currentUser?.photoURL;
  }

}
