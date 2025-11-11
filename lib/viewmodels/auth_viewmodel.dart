import 'package:flutter/foundation.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isAdmin => _isAdmin;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Login with email and password
  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authService.signInWithEmail(email, password);
      _isAdmin = _currentUser?.isAdmin ?? false;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authService.signInWithGoogle();
      _isAdmin = _currentUser?.isAdmin ?? false;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmail(
      String email, String password, String displayName) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authService.registerWithEmail(email, password, displayName);
      _isAdmin = _currentUser?.isAdmin ?? false;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _isAdmin = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Check authentication state
  Future<void> checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final firestoreService = FirestoreService();
        _currentUser = await firestoreService.getUserProfile(user.uid);
        _isAdmin = _currentUser?.isAdmin ?? false;
      } catch (e) {
        _currentUser = null;
        _isAdmin = false;
        _setError('Không thể tải dữ liệu người dùng: ${e.toString()}');
      }
    } else {
      _currentUser = null;
      _isAdmin = false;
    }
    notifyListeners();
  }

  // Method to set admin status
  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }
}