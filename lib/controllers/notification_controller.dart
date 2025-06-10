import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../core/utils/status_calculator.dart';
import '../core/constants/message_templates.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/whatsapp_service.dart';

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
        _notifications = await DatabaseService.getAllNotifications();
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

  Future<void> scheduleClientNotifications() async {
    try {
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();
      
      for (final client in clients) {
        if (!client.hasExited) {
          await _scheduleNotificationsForClient(client, settings);
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _scheduleNotificationsForClient(ClientModel client, Map<String, dynamic> settings) async {
    final clientSettings = settings['clientNotificationSettings'];
    final tiers = [
      clientSettings['firstTier'],
      clientSettings['secondTier'],
      clientSettings['thirdTier'],
    ];

    for (final tier in tiers) {
      final days = tier['days'] as int;
      final frequency = tier['frequency'] as int;
      final message = tier['message'] as String;

      if (client.daysRemaining <= days && client.daysRemaining > 0) {
        for (int i = 0; i < frequency; i++) {
          final scheduledTime = DateTime.now().add(Duration(hours: i * (24 ~/ frequency)));
          
          // Create notification record
          final notification = NotificationModel(
            id: '${client.id}_${scheduledTime.millisecondsSinceEpoch}',
            type: NotificationType.clientExpiring,
            title: MessageTemplates.notificationTitles['client_expiring'] ?? 'تنبيه انتهاء تأشيرة',
            message: MessageTemplates.formatMessage(message, {
              'clientName': client.clientName,
              'daysRemaining': client.daysRemaining.toString(),
            }),
            targetUserId: client.createdBy,
            clientId: client.id,
            priority: _getPriorityFromDays(client.daysRemaining),
            createdAt: DateTime.now(),
            scheduledFor: scheduledTime,
          );
          
          await DatabaseService.saveNotification(notification);
          
          await NotificationService.scheduleClientNotification(
            clientId: client.id,
            clientName: client.clientName,
            message: message,
            scheduledTime: scheduledTime,
          );
        }
        break; // Only schedule for the most relevant tier
      }
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
        title: MessageTemplates.notificationTitles['client_expiring'] ?? 'تنبيه انتهاء تأشيرة',
        message: MessageTemplates.formatMessage(defaultMessage, {
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
        title: MessageTemplates.notificationTitles['user_validation'] ?? 'تنبيه انتهاء صلاحية الحساب',
        message: MessageTemplates.formatMessage(defaultMessage, {
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

  // Helper methods for filtering notifications
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