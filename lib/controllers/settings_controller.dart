import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/database_service.dart';

class SettingsController extends ChangeNotifier {
  Map<String, dynamic> _adminSettings = {};
  Map<String, dynamic> _userSettings = {};
  bool _isLoading = false;

  Map<String, dynamic> get adminSettings => _adminSettings;
  Map<String, dynamic> get userSettings => _userSettings;
  bool get isLoading => _isLoading;

  Future<void> loadAdminSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _adminSettings = await DatabaseService.getAdminSettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> loadUserSettings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userSettings = await DatabaseService.getUserSettings(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateAdminSettings(Map<String, dynamic> settings) async {
    try {
      await DatabaseService.saveAdminSettings(settings);
      _adminSettings = settings;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await DatabaseService.saveUserSettings(userId, settings);
      _userSettings = settings;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateStatusSettings(StatusSettings settings) async {
    try {
      _adminSettings['clientStatusSettings'] = settings.toMap();
      await DatabaseService.saveAdminSettings(_adminSettings);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      _adminSettings['clientNotificationSettings'] = {
        'firstTier': settings.clientTiers[0].toMap(),
        'secondTier': settings.clientTiers[1].toMap(),
        'thirdTier': settings.clientTiers[2].toMap(),
      };
      _adminSettings['userNotificationSettings'] = {
        'firstTier': settings.userTiers[0].toMap(),
        'secondTier': settings.userTiers[1].toMap(),
        'thirdTier': settings.userTiers[2].toMap(),
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateWhatsAppMessages(String clientMessage, String userMessage) async {
    try {
      _adminSettings['whatsappMessages'] = {
        'clientMessage': clientMessage,
        'userMessage': userMessage,
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}
