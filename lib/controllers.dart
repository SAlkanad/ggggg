import 'package:flutter/material.dart';
import 'models.dart';
import 'services.dart';
import 'core.dart';
import 'dart:io';
import 'settings_screens.dart';
class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get rememberMe => _rememberMe;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  AuthController() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkBiometricAvailability();
    
    final autoLoginUser = await AuthService.checkAutoLogin();
    if (autoLoginUser != null) {
      _currentUser = autoLoginUser;
      _biometricEnabled = await BiometricService.isBiometricEnabled(_currentUser!.id);
      notifyListeners();
    }
    
    _rememberMe = await AuthService.shouldAutoLogin();
    notifyListeners();
  }

  Future<void> _checkBiometricAvailability() async {
    _biometricAvailable = await BiometricService.isBiometricAvailable();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await AuthService.login(username, password);
      
      await AuthService.saveCredentials(username, password, _rememberMe);
      
      _biometricEnabled = await BiometricService.isBiometricEnabled(_currentUser!.id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<bool> loginWithBiometric(String username) async {
    if (!_biometricAvailable) return false;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await AuthService.loginWithBiometric(username);
      if (_currentUser != null) {
        _biometricEnabled = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> enableBiometric() async {
    if (_currentUser != null && _biometricAvailable) {
      await BiometricService.enableBiometric(_currentUser!.id);
      _biometricEnabled = true;
      notifyListeners();
    }
  }

  Future<void> disableBiometric() async {
    if (_currentUser != null) {
      await BiometricService.disableBiometric(_currentUser!.id);
      _biometricEnabled = false;
      notifyListeners();
    }
  }

  Future<bool> checkBiometricAvailability() async {
    _biometricAvailable = await BiometricService.isBiometricAvailable();
    notifyListeners();
    return _biometricAvailable;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return await AuthService.getSavedCredentials();
  }
}

class ClientController extends ChangeNotifier {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  List<UserModel> _users = [];
  Map<String, UserModel> _userCache = {};
  bool _isLoading = false;
  ClientFilter _currentFilter = ClientFilter();

  List<ClientModel> get clients => _filteredClients.isEmpty && !_currentFilter.hasActiveFilters 
      ? _clients 
      : _filteredClients;
  bool get isLoading => _isLoading;
  ClientFilter get currentFilter => _currentFilter;
  List<UserModel> get users => _users;

  Future<void> loadClients(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _clients = await DatabaseService.getAllClients();
        _users = await DatabaseService.getAllUsers();
        _buildUserCache();
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

      await _applyCurrentFilter(userId, isAdmin: isAdmin);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  void _buildUserCache() {
    _userCache.clear();
    for (final user in _users) {
      _userCache[user.id] = user;
    }
  }

  Future<void> applyFilter(ClientFilter filter, String userId, {bool isAdmin = false}) async {
    _currentFilter = filter;
    await _applyCurrentFilter(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  Future<void> _applyCurrentFilter(String userId, {bool isAdmin = false}) async {
    try {
      _filteredClients = await DatabaseService.getFilteredClients(
        userId: isAdmin ? null : userId,
        isAdmin: isAdmin,
        filterByUser: _currentFilter.userFilter,
        filterByStatus: _currentFilter.statusFilter,
        filterByVisaType: _currentFilter.visaTypeFilter,
        startDate: _currentFilter.startDate,
        endDate: _currentFilter.endDate,
      );

      if (_currentFilter.searchQuery != null && _currentFilter.searchQuery!.isNotEmpty) {
        final searchLower = _currentFilter.searchQuery!.toLowerCase();
        _filteredClients = _filteredClients.where((client) {
          final name = client.clientName.toLowerCase();
          final phone = client.clientPhone;
          final secondPhone = client.secondPhone ?? '';
          
          return name.contains(searchLower) ||
              phone.contains(_currentFilter.searchQuery!) ||
              secondPhone.contains(_currentFilter.searchQuery!);
        }).toList();
      }
    } catch (e) {
      _filteredClients = [];
    }
  }

  void clearFilter() {
    _currentFilter = ClientFilter();
    _filteredClients = [];
    notifyListeners();
  }

  Future<void> searchClients(String query, String userId, {bool isAdmin = false}) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await _applyCurrentFilter(userId, isAdmin: isAdmin);
    notifyListeners();
  }

  void clearSearch() {
    _currentFilter = _currentFilter.copyWith(searchQuery: '');
    _filteredClients = [];
    notifyListeners();
  }

  Future<void> addClient(ClientModel client, List<File>? images) async {
    try {
      await DatabaseService.saveClient(client, images);
      
      _clients.insert(0, client);
      
      if (_currentFilter.hasActiveFilters) {
        final authController = _currentFilter.userFilter ?? client.createdBy;
        await _applyCurrentFilter(authController);
      }
      
      await DatabaseService.clearCache();
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
        _filteredClients[filteredIndex] = client;
      }
      
      await DatabaseService.clearCache();
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
      
      await DatabaseService.clearCache();
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
      
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> refreshClients(String userId, {bool isAdmin = false}) async {
    await StatusUpdateService.forceUpdateAllStatuses();
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

  String? getUserNameById(String userId) {
    try {
      if (_userCache.containsKey(userId)) {
        return _userCache[userId]!.name;
      }
      final user = _users.firstWhere((u) => u.id == userId);
      return user.name;
    } catch (e) {
      return null;
    }
  }

  int getClientsCount() => _clients.length;
  
  int getActiveClientsCount() => _clients.where((c) => !c.hasExited).length;
  
  int getExitedClientsCount() => _clients.where((c) => c.hasExited).length;
}

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
      await DatabaseService.clearCache();
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
        await DatabaseService.clearCache();
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
      await DatabaseService.clearCache();
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
        await DatabaseService.clearCache();
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
        await DatabaseService.clearCache();
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
        await DatabaseService.clearCache();
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
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.userValidationExpiring,
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
}

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        final settings = await DatabaseService.getAdminSettings();
        final adminFilters = settings['adminFilters'] ?? {};
        final showOnlyMyNotifications = adminFilters['showOnlyMyNotifications'] ?? false;
        
        if (showOnlyMyNotifications) {
          _notifications = await DatabaseService.getNotificationsByUser(userId);
        } else {
          _notifications = await DatabaseService.getAllNotifications();
        }
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
      
      await NotificationService.showNotification(
        id: notification.hashCode,
        title: notification.title,
        body: notification.message,
        payload: notification.id,
      );
      
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

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }
}

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
      await DatabaseService.clearCache();
      await StatusUpdateService.forceUpdateAllStatuses();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await DatabaseService.saveUserSettings(userId, settings);
      _userSettings = settings;
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateStatusSettings(StatusSettings settings) async {
    try {
      _adminSettings['clientStatusSettings'] = settings.toMap();
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      await StatusUpdateService.forceUpdateAllStatuses();
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
      await DatabaseService.clearCache();
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
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAdminFilters(bool showOnlyMyClients, bool showOnlyMyNotifications) async {
    try {
      _adminSettings['adminFilters'] = {
        'showOnlyMyClients': showOnlyMyClients,
        'showOnlyMyNotifications': showOnlyMyNotifications,
      };
      await DatabaseService.saveAdminSettings(_adminSettings);
      await DatabaseService.clearCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}