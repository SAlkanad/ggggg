import 'dart:async';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../core/utils/status_calculator.dart';
import '../core/constants/message_templates.dart';
import 'database_service.dart';
import 'notification_service.dart';

class BackgroundService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void startBackgroundTasks() {
    if (_isRunning) return;
    
    _isRunning = true;
    _timer = Timer.periodic(Duration(hours: 1), (timer) {
      _runBackgroundTasks();
    });
  }

  static void stopBackgroundTasks() {
    _timer?.cancel();
    _isRunning = false;
  }

  static Future<void> _runBackgroundTasks() async {
    try {
      await _checkClientNotifications();
      await _checkUserValidations();
      await _autoFreezeExpiredUsers();
    } catch (e) {
      print('Background task error: $e');
    }
  }

  static Future<void> _checkClientNotifications() async {
    try {
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();
      
      for (final client in clients) {
        if (!client.hasExited) {
          await _scheduleClientNotifications(client, settings);
        }
      }
    } catch (e) {
      print('Client notification check error: $e');
    }
  }

  static Future<void> _scheduleClientNotifications(ClientModel client, Map<String, dynamic> settings) async {
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
        // Create notification record
        final notification = NotificationModel(
          id: '${client.id}_${DateTime.now().millisecondsSinceEpoch}',
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
        );
        
        await DatabaseService.saveNotification(notification);
        
        // Schedule local notifications
        for (int i = 0; i < frequency; i++) {
          final scheduledTime = DateTime.now().add(Duration(hours: i * (24 ~/ frequency)));
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

  static Future<void> _checkUserValidations() async {
    try {
      final users = await DatabaseService.getAllUsers();
      final settings = await DatabaseService.getAdminSettings();
      
      for (final user in users) {
        if (user.validationEndDate != null && !user.isFrozen) {
          await _scheduleUserNotifications(user, settings);
        }
      }
    } catch (e) {
      print('User validation check error: $e');
    }
  }

  static Future<void> _scheduleUserNotifications(UserModel user, Map<String, dynamic> settings) async {
    final daysRemaining = user.validationEndDate!.difference(DateTime.now()).inDays;
    final userSettings = settings['userNotificationSettings'];
    final tiers = [
      userSettings['firstTier'],
      userSettings['secondTier'],
      userSettings['thirdTier'],
    ];

    for (final tier in tiers) {
      final days = tier['days'] as int;
      final frequency = tier['frequency'] as int;
      final message = tier['message'] as String;

      if (daysRemaining <= days && daysRemaining > 0) {
        // Create notification record
        final notification = NotificationModel(
          id: '${user.id}_validation_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.userValidationExpiring,
          title: MessageTemplates.notificationTitles['user_validation'] ?? 'تنبيه انتهاء صلاحية الحساب',
          message: MessageTemplates.formatMessage(message, {
            'userName': user.name,
            'daysRemaining': daysRemaining.toString(),
          }),
          targetUserId: user.id,
          priority: _getPriorityFromDays(daysRemaining),
          createdAt: DateTime.now(),
        );
        
        await DatabaseService.saveNotification(notification);
        
        // Schedule local notifications
        for (int i = 0; i < frequency; i++) {
          await NotificationService.sendUserValidationNotification(
            userId: user.id,
            message: message,
          );
        }
        break; // Only schedule for the most relevant tier
      }
    }
  }

  static Future<void> _autoFreezeExpiredUsers() async {
    try {
      final users = await DatabaseService.getAllUsers();
      
      for (final user in users) {
        if (user.validationEndDate != null && 
            user.validationEndDate!.isBefore(DateTime.now()) &&
            !user.isFrozen) {
          await DatabaseService.freezeUser(user.id, 'انتهت صلاحية الحساب تلقائياً');
          
          // Send freeze notification
          final freezeNotification = NotificationModel(
            id: '${user.id}_freeze_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.userValidationExpiring,
            title: MessageTemplates.notificationTitles['user_freeze'] ?? 'تم تجميد الحساب',
            message: MessageTemplates.userMessages['validation_expired'] ?? 'انتهت صلاحية حسابك. تم تجميد الحساب.',
            targetUserId: user.id,
            priority: NotificationPriority.high,
            createdAt: DateTime.now(),
          );
          
          await DatabaseService.saveNotification(freezeNotification);
        }
      }
    } catch (e) {
      print('Auto-freeze error: $e');
    }
  }

  static NotificationPriority _getPriorityFromDays(int days) {
    if (days <= 2) return NotificationPriority.high;
    if (days <= 5) return NotificationPriority.medium;
    return NotificationPriority.low;
  }
}