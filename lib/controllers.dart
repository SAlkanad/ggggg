import 'package:flutter/material.dart';
import 'models.dart';
import 'services.dart';
import 'core.dart';
import 'biometrics_service.dart';
import 'dart:io';

// controllers/auth_controller.dart
class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _biometricsEnabled = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get rememberMe => _rememberMe;
  bool get biometricsEnabled => _biometricsEnabled;

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  set biometricsEnabled(bool value) {
    _biometricsEnabled = value;
    BiometricsService.setEnabled(value);
    notifyListeners();
  }

  AuthController() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final autoLoginUser = await AuthService.checkAutoLogin();
    if (autoLoginUser != null) {
      _currentUser = autoLoginUser;
      notifyListeners();
    }
    
    _rememberMe = await AuthService.shouldAutoLogin();
    _biometricsEnabled = await BiometricsService.isEnabled();
    notifyListeners();
  }

  Future<bool> login(String username, String password, {bool useBiometrics = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (useBiometrics) {
        final biometricResult = await AuthService.authenticateWithBiometrics();
        if (!biometricResult) {
          _isLoading = false;
          notifyListeners();
          throw Exception('فشل في التحقق بالبصمة');
        }
      }

      _currentUser = await AuthService.login(username, password);
      
      await AuthService.saveCredentials(username, password, _rememberMe);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<bool> loginWithBiometrics() async {
    if (!_biometricsEnabled) return false;
    
    final credentials = await AuthService.getSavedCredentials();
    final username = credentials['username'];
    final password = credentials['password'];
    
    if (username == null || password == null) return false;
    
    return await login(username, password, useBiometrics: true);
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return await AuthService.getSavedCredentials();
  }

  Future<bool> checkBiometricsAvailability() async {
    return await BiometricsService.isAvailable();
  }

  Future<List<String>> getAvailableBiometrics() async {
    return await BiometricsService.getAvailableBiometricNames();
  }
}

// controllers/client_controller.dart
class ClientController extends ChangeNotifier {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ClientFilter _currentFilter = ClientFilter();
  bool _showOnlyOwnClients = false;

  List<ClientModel> get clients => _filteredClients.isEmpty && !_currentFilter.hasActiveFilters
      ? _clients 
      : _filteredClients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ClientFilter get currentFilter => _currentFilter;
  bool get showOnlyOwnClients => _showOnlyOwnClients;

  void setShowOnlyOwnClients(bool value) {
    _showOnlyOwnClients = value;
    notifyListeners();
  }

  Future<void> loadClients(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _clients = await DatabaseService.getClientsByUser(userId, showOnlyOwnClients: _showOnlyOwnClients);
      } else {
        _clients = await DatabaseService.getClientsByUser(userId);
      }
      
      final settings = await DatabaseService.getAdminSettings();
      final statusSettings = settings['clientStatusSettings'] ?? {};
      final greenDays = statusSettings['greenDays'] ?? 30;
      final yellowDays = statusSettings['yellowDays'] ?? 30;
      final redDays = statusSettings['redDays'] ?? 1;
      
      for (int i = 0; i < _clients.length; i++) {
        final updatedClient = _clients[i].copyWith(
          status: StatusCalculator.calculateStatus(
            _clients[i].entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          ),
          daysRemaining: StatusCalculator.calculateDaysRemaining(_clients[i].entryDate),
        );
        _clients[i] = updatedClient;
      }

      await _applyCurrentFilters(userId, isAdmin: isAdmin);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> searchClients(String query, String userId, {bool isAdmin = false}) async {
    _searchQuery = query;
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await _applyCurrentFilters(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  Future<void> applyFilter(ClientFilter filter, String userId, {bool isAdmin = false}) async {
    _currentFilter = filter;
    await _applyCurrentFilters(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  Future<void> _applyCurrentFilters(String userId, {bool isAdmin = false}) async {
    try {
      if (_currentFilter.hasActiveFilters) {
        _filteredClients = await DatabaseService.getFilteredClients(
          _currentFilter, 
          userId, 
          isAdmin: isAdmin,
          showOnlyOwnClients: _showOnlyOwnClients
        );
      } else {
        _filteredClients = [];
      }
    } catch (e) {
      _filteredClients = [];
      throw e;
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _currentFilter = ClientFilter();
    _filteredClients = [];
    notifyListeners();
  }

  Future<void> addClient(ClientModel client, List<File>? images) async {
    try {
      await DatabaseService.saveClient(client, images);
      
      _clients.insert(0, client);
      
      if (_currentFilter.hasActiveFilters && _currentFilter.matchesClient(client)) {
        _filteredClients.insert(0, client);
      }
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClient(ClientModel client, List<File>? images) async {
    try {
      await DatabaseService.saveClient(client, images);
      
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
      }
      
      final filteredIndex = _filteredClients.indexWhere((c) => c.id == client.id);
      if (filteredIndex != -1) {
        if (_currentFilter.matchesClient(client)) {
          _filteredClients[filteredIndex] = client;
        } else {
          _filteredClients.removeAt(filteredIndex);
        }
      }
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClientStatus(String clientId, ClientStatus status) async {
    try {
      await DatabaseService.updateClientStatus(clientId, status);
      
      final index = _clients.indexWhere((client) => client.id == clientId);
      if (index != -1) {
        _clients[index] = _clients[index].copyWith(
          status: status,
          hasExited: status == ClientStatus.white,
        );
      }
      
      final filteredIndex = _filteredClients.indexWhere((client) => client.id == clientId);
      if (filteredIndex != -1) {
        _filteredClients[filteredIndex] = _filteredClients[filteredIndex].copyWith(
          status: status,
          hasExited: status == ClientStatus.white,
        );
      }
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await DatabaseService.deleteClient(clientId);
      
      _clients.removeWhere((client) => client.id == clientId);
      _filteredClients.removeWhere((client) => client.id == clientId);
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshClients(String userId, {bool isAdmin = false}) async {
    await loadClients(userId, isAdmin: isAdmin);
  }

  List<ClientModel> getClientsByStatus(ClientStatus status) {
    final currentClients = clients;
    return currentClients.where((client) => client.status == status).toList();
  }

  List<ClientModel> getExpiringClients(int days) {
    final currentClients = clients;
    return currentClients.where((client) => 
      client.daysRemaining <= days && 
      client.daysRemaining >= 0 && 
      !client.hasExited
    ).toList();
  }

  int getClientsCount() => _clients.length;
  
  int getActiveClientsCount() => _clients.where((c) => !c.hasExited).length;
  
  int getExitedClientsCount() => _clients.where((c) => c.hasExited).length;

  // Get list of users who created clients (for filtering)
  List<String> getCreatedByUsers() {
    final users = <String>{};
    for (final client in _clients) {
      if (client.createdByName != null) {
        users.add(client.createdByName!);
      }
    }
    return users.toList()..sort();
  }
}

// controllers/user_controller.dart
class UserController extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await DatabaseService.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      await DatabaseService.saveUser(user);
      _users.insert(0, user);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await DatabaseService.saveUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await DatabaseService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> freezeUser(String userId, String reason) async {
    try {
      await DatabaseService.freezeUser(userId, reason);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: true,
          freezeReason: reason,
          validationEndDate: _users[index].validationEndDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> unfreezeUser(String userId) async {
    try {
      await DatabaseService.unfreezeUser(userId);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: false,
          freezeReason: null,
          validationEndDate: _users[index].validationEndDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> setUserValidation(String userId, DateTime endDate) async {
    try {
      await DatabaseService.setUserValidation(userId, endDate);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          password: _users[index].password,
          role: _users[index].role,
          name: _users[index].name,
          phone: _users[index].phone,
          email: _users[index].email,
          isActive: _users[index].isActive,
          isFrozen: _users[index].isFrozen,
          freezeReason: _users[index].freezeReason,
          validationEndDate: endDate,
          createdAt: _users[index].createdAt,
          createdBy: _users[index].createdBy,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<List<ClientModel>> getUserClients(String userId) async {
    try {
      return await DatabaseService.getClientsByUser(userId);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendNotificationToUser(String userId, String message) async {
    try {
      final notification = NotificationModel(
        id: '${userId}_admin_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.adminMessage,
        title: 'إشعار من الإدارة',
        message: message,
        targetUserId: userId,
        createdAt: DateTime.now(),
      );
      
      await DatabaseService.saveNotification(notification);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendNotificationToAllUsers(String message) async {
    try {
      for (final user in _users) {
        await sendNotificationToUser(user.id, message);
      }
    } catch (e) {
      throw e;
    }
  }

  UserModel? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  List<UserModel> getActiveUsers() {
    return _users.where((user) => user.isActive && !user.isFrozen).toList();
  }

  List<UserModel> getExpiringUsers(int days) {
    final now = DateTime.now();
    return _users.where((user) {
      if (user.validationEndDate == null) return false;
      final daysRemaining = user.validationEndDate!.difference(now).inDays;
      return daysRemaining <= days && daysRemaining >= 0;
    }).toList();
  }
}

// controllers/notification_controller.dart
class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _showOnlyOwnNotifications = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get showOnlyOwnNotifications => _showOnlyOwnNotifications;

  void setShowOnlyOwnNotifications(bool value) {
    _showOnlyOwnNotifications = value;
    notifyListeners();
  }

  Future<void> loadNotifications(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _notifications = await DatabaseService.getNotificationsByUser(
          userId, 
          showOnlyOwnNotifications: _showOnlyOwnNotifications
        );
      } else {
        _notifications = await DatabaseService.getNotificationsByUser(userId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await DatabaseService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          targetUserId: _notifications[index].targetUserId,
          clientId: _notifications[index].clientId,
          isRead: true,
          priority: _notifications[index].priority,
          createdAt: _notifications[index].createdAt,
          scheduledFor: _notifications[index].scheduledFor,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToClient(ClientModel client, String message) async {
    try {
      final formattedMessage = MessageTemplates.formatMessage(
        message,
        {
          'clientName': client.clientName,
          'daysRemaining': client.daysRemaining.toString(),
        }
      );
      
      await WhatsAppService.sendClientMessage(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
        message: formattedMessage,
        clientName: client.clientName,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> callClient(ClientModel client) async {
    try {
      await WhatsAppService.callClient(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToUser(UserModel user, String message) async {
    try {
      final formattedMessage = MessageTemplates.formatMessage(
        message,
        {
          'userName': user.name,
        }
      );
      
      await WhatsAppService.sendUserMessage(
        phoneNumber: user.phone,
        message: formattedMessage,
        userName: user.name,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> createClientExpiringNotification(ClientModel client) async {
    try {
      final settings = await DatabaseService.getAdminSettings();
      final whatsappMessages = settings['whatsappMessages'] ?? {};
      final defaultMessage = whatsappMessages['clientMessage'] ?? 
          MessageTemplates.whatsappMessages['client_default'];

      final notification = NotificationModel(
        id: '${client.id}_expiring_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.clientExpiring,
        title: 'تنبيه انتهاء تأشيرة',
        message: MessageTemplates.formatMessage(defaultMessage!, {
          'clientName': client.clientName,
          'daysRemaining': client.daysRemaining.toString(),
        }),
        targetUserId: client.createdBy,
        clientId: client.id,
        priority: _getPriorityFromDays(client.daysRemaining),
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveNotification(notification);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> createUserValidationNotification(UserModel user) async {
    try {
      final daysRemaining = user.validationEndDate?.difference(DateTime.now()).inDays ?? 0;
      final settings = await DatabaseService.getAdminSettings();
      final whatsappMessages = settings['whatsappMessages'] ?? {};
      final defaultMessage = whatsappMessages['userMessage'] ?? 
          MessageTemplates.whatsappMessages['user_default'];

      final notification = NotificationModel(
        id: '${user.id}_validation_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.userValidationExpiring,
        title: 'تنبيه انتهاء صلاحية الحساب',
        message: MessageTemplates.formatMessage(defaultMessage!, {
          'userName': user.name,
          'daysRemaining': daysRemaining.toString(),
        }),
        targetUserId: user.id,
        priority: _getPriorityFromDays(daysRemaining),
        createdAt: DateTime.now(),
      );

      await DatabaseService.saveNotification(notification);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  NotificationPriority _getPriorityFromDays(int days) {
    if (days <= 2) return NotificationPriority.high;
    if (days <= 5) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  List<NotificationModel> getClientNotifications() {
    return _notifications.where((n) => n.type == NotificationType.clientExpiring).toList();
  }

  List<NotificationModel> getUserNotifications() {
    return _notifications.where((n) => n.type == NotificationType.userValidationExpiring).toList();
  }

  List<NotificationModel> getAdminMessages() {
    return _notifications.where((n) => n.type == NotificationType.adminMessage).toList();
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> getHighPriorityNotifications() {
    return _notifications.where((n) => n.priority == NotificationPriority.high && !n.isRead).toList();
  }
}

// controllers/settings_controller.dart
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

  Future<void> updateDisplaySettings({
    bool? showOnlyOwnClients,
    bool? showOnlyOwnNotifications,
  }) async {
    try {
      if (_adminSettings['displaySettings'] == null) {
        _adminSettings['displaySettings'] = {};
      }
      
      if (showOnlyOwnClients != null) {
        _adminSettings['displaySettings']['showOnlyOwnClients'] = showOnlyOwnClients;
      }
      
      if (showOnlyOwnNotifications != null) {
        _adminSettings['displaySettings']['showOnlyOwnNotifications'] = showOnlyOwnNotifications;
      }
      
      await DatabaseService.saveAdminSettings(_adminSettings);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  bool getShowOnlyOwnClients() {
    return _adminSettings['displaySettings']?['showOnlyOwnClients'] ?? false;
  }

  bool getShowOnlyOwnNotifications() {
    return _adminSettings['displaySettings']?['showOnlyOwnNotifications'] ?? false;
  }

  Future<void> updateBiometricsSettings(String userId, bool enabled) async {
    try {
      if (_userSettings['profile'] == null) {
        _userSettings['profile'] = {};
      }
      
      _userSettings['profile']['biometricsEnabled'] = enabled;
      await DatabaseService.saveUserSettings(userId, _userSettings);
      await BiometricsService.setEnabled(enabled);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  bool getBiometricsEnabled() {
    return _userSettings['profile']?['biometricsEnabled'] ?? false;
  }
}