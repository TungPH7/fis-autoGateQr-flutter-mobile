import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _state = AuthState.loading;
        notifyListeners();

        _user = await _authService.getUserProfile(firebaseUser.uid);
        if (_user != null) {
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signInWithEmailPassword(email, password);

      if (_user != null) {
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Không thể đăng nhập';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _state = AuthState.error;
      _errorMessage = AuthService.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? employeeId,
    String userType = 'employee',
    String? department,
    String? company,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        employeeId: employeeId,
        userType: userType,
        department: department,
        company: company,
      );

      if (_user != null) {
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Không thể đăng ký';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _state = AuthState.error;
      _errorMessage = AuthService.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = AuthState.error;
      _errorMessage = AuthService.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String token) async {
    if (_user != null) {
      await _authService.updateFCMToken(_user!.uid, token);
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_authService.currentUser != null) {
      _user = await _authService.getUserProfile(_authService.currentUser!.uid);
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }
}