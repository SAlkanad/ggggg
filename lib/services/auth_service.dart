import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../core/constants/firebase_constants.dart';
import 'biometric_auth_service.dart';

class AuthService {
  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserId = 'user_id';

  static Future<UserModel> login(String username, String password, {bool rememberMe = false}) async {
    try {
      final hashedPassword = _hashPassword(password);
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }

      final userData = querySnapshot.docs.first.data();
      final user = UserModel.fromMap(userData);

      if (!user.isActive) {
        throw Exception('الحساب غير مفعل');
      }

      if (user.isFrozen) {
        throw Exception('تم تجميد الحساب: ${user.freezeReason ?? "غير محدد"}');
      }

      if (user.validationEndDate != null && 
          user.validationEndDate!.isBefore(DateTime.now())) {
        throw Exception('انتهت صلاحية الحساب');
      }

      _currentUser = user;

      if (rememberMe) {
        await _saveLoginCredentials(username, password, user.id);
      } else {
        await _clearLoginCredentials();
      }

      return user;
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول: ${e.toString()}');
    }
  }

  static Future<UserModel?> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      
      if (!rememberMe) return null;

      // Check if biometric is enabled and available
      if (await BiometricService.isBiometricEnabled()) {
        final authenticated = await BiometricService.authenticateForLogin();
        if (!authenticated) {
          return null; // User cancelled biometric auth
        }
      }

      final username = prefs.getString(_keyUsername);
      final password = prefs.getString(_keyPassword);
      
      if (username == null || password == null) return null;

      return await login(username, password, rememberMe: true);
    } catch (e) {
      await _clearLoginCredentials();
      return null;
    }
  }

  static Future<bool> loginWithBiometric() async {
    try {
      if (!await BiometricService.isBiometricEnabled()) {
        throw Exception('المصادقة البيومترية غير مفعلة');
      }

      if (!await BiometricService.isBiometricAvailable()) {
        throw Exception('المصادقة البيومترية غير متوفرة على هذا الجهاز');
      }

      final authenticated = await BiometricService.authenticateForLogin();
      if (!authenticated) {
        throw Exception('فشل في تأكيد الهوية');
      }

      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_keyUsername);
      final password = prefs.getString(_keyPassword);

      if (username == null || password == null) {
        throw Exception('لا توجد بيانات دخول محفوظة');
      }

      await login(username, password, rememberMe: true);
      return true;
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول بالبصمة: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, false);
  }

  static Future<void> enableBiometric() async {
    if (!await BiometricService.isBiometricAvailable()) {
      throw Exception('المصادقة البيومترية غير متوفرة على هذا الجهاز');
    }

    final authenticated = await BiometricService.authenticateWithBiometrics(
      localizedReason: 'تأكيد الهوية لتفعيل المصادقة البيومترية',
    );

    if (!authenticated) {
      throw Exception('فشل في تأكيد الهوية');
    }

    await BiometricService.setBiometricEnabled(true);
  }

  static Future<void> disableBiometric() async {
    await BiometricService.disableBiometric();
  }

  static Future<void> _saveLoginCredentials(String username, String password, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyRememberMe, true);
  }

  static Future<void> _clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyUserId);
    await prefs.setBool(_keyRememberMe, false);
  }

  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername),
      'password': prefs.getString(_keyPassword),
      'rememberMe': (prefs.getBool(_keyRememberMe) ?? false).toString(),
    };
  }

  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}