import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

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
      _users.add(user);
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
      await NotificationService.sendUserValidationNotification(
        userId: userId,
        message: message,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendNotificationToAllUsers(String message) async {
    try {
      for (final user in _users) {
        await NotificationService.sendUserValidationNotification(
          userId: user.id,
          message: message,
        );
      }
    } catch (e) {
      throw e;
    }
  }
}
