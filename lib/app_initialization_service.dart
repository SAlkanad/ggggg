import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'services.dart';
import 'firebase_options.dart';

class AppInitializationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await _initializeFirebase();

      // Initialize notifications
      await _initializeNotifications();

      // Initialize timezone
      tz.initializeTimeZones();

      // Request permissions
      await _requestPermissions();

      // Create default admin if needed
      await AuthService.createDefaultAdmin();

      // Start background services
      _startBackgroundServices();

      print('✅ App initialization completed successfully');
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    }
  }

  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    print('✅ Firebase initialized');
  }

  static Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ Local notifications initialized');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  static Future<void> _requestPermissions() async {
    // Request camera permission
    await Permission.camera.request();

    // Request storage permissions
    await Permission.storage.request();

    // Request phone permission
    await Permission.phone.request();

    // Request notification permission
    await Permission.notification.request();

    print('✅ Permissions requested');
  }

  static void _startBackgroundServices() {
    BackgroundService.startBackgroundTasks();
    StatusUpdateService.startAutoStatusUpdate();
    print('✅ Background services started');
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'passenger_channel',
      'Passenger Notifications',
      channelDescription: 'Notifications for passenger visa expiry',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'passenger_channel',
      'Passenger Notifications',
      channelDescription: 'Notifications for passenger visa expiry',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Fixed timezone scheduling
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}