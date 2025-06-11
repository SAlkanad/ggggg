import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricsService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if biometrics is available on device
  static Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Check if biometrics is enabled in app settings
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometrics_enabled') ?? false;
  }

  // Enable/disable biometrics in app settings
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometrics
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access the app',
  }) async {
    try {
      final bool isEnabled = await BiometricsService.isEnabled();
      if (!isEnabled) {
        return false;
      }

      final bool isAvailable = await BiometricsService.isAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Get biometric type display name
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Pattern/PIN';
      case BiometricType.strong:
        return 'Strong Authentication';
      default:
        return 'Biometric';
    }
  }

  // Get available biometric types as display strings
  static Future<List<String>> getAvailableBiometricNames() async {
    final types = await getAvailableBiometrics();
    return types.map((type) => getBiometricTypeName(type)).toList();
  }

  // Check if device supports any biometric authentication
  static Future<bool> hasAnyBiometrics() async {
    final types = await getAvailableBiometrics();
    return types.isNotEmpty;
  }
}