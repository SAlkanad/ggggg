import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }

      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics({
    String localizedReason = 'يرجى تأكيد هويتك للدخول',
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  static Future<bool> authenticateForLogin() async {
    if (!await isBiometricEnabled()) {
      return false;
    }

    return await authenticateWithBiometrics(
      localizedReason: 'تأكيد الهوية لتسجيل الدخول',
    );
  }

  static Future<bool> authenticateForSettings() async {
    return await authenticateWithBiometrics(
      localizedReason: 'تأكيد الهوية للوصول إلى الإعدادات',
    );
  }

  static String getBiometricTypeText(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'بصمة الوجه';
      case BiometricType.fingerprint:
        return 'بصمة الإصبع';
      case BiometricType.iris:
        return 'بصمة العين';
      case BiometricType.weak:
        return 'مصادقة ضعيفة';
      case BiometricType.strong:
        return 'مصادقة قوية';
      default:
        return 'مصادقة بيومترية';
    }
  }

  static Future<void> disableBiometric() async {
    await setBiometricEnabled(false);
  }
}