import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAutoLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAutoLoading => _isAutoLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initializeAuth() async {
    _isAutoLoading = true;
    notifyListeners();

    try {
      _currentUser = await AuthService.tryAutoLogin();
      _isAutoLoading = false;
      notifyListeners();
    } catch (e) {
      _isAutoLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await AuthService.login(username, password, rememberMe: rememberMe);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return await AuthService.getSavedCredentials();
  }
}