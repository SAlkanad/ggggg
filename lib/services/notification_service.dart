import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../core/utils/status_calculator.dart';

class NotificationService {
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static Future<void> initialize() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleClientNotification({
    required String clientId,
    required String clientName,
    required String message,
    required DateTime scheduledTime,
  }) async {
    final processedMessage = message.contains('{clientName}')
        ? message.replaceAll('{clientName}', clientName)
        : '$clientName: $message';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      clientId.hashCode,
      'تنبيه انتهاء تأشيرة',
      processedMessage,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'client_expiry',
          'Client Visa Expiry',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> sendUserValidationNotification({
    required String userId,
    required String message,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      userId.hashCode,
      'تنبيه انتهاء صلاحية الحساب',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'user_validation',
          'User Validation Expiry',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
