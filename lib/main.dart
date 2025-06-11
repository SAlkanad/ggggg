import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:corporation_no_icon/corporation_no_icon.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'controllers.dart';
import 'routes.dart';
import 'core.dart';
import 'services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize other services
  await NotificationService.initialize();
  tz.initializeTimeZones();

  // Start background services
  BackgroundService.startBackgroundTasks();
  StatusUpdateService.startAutoStatusUpdate();

  // Auto-login if credentials are saved
  await AuthService.checkAutoLogin();

  runApp(PassengersApp());
}

class PassengersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ClientController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: MaterialApp(
        title: 'نظام إدارة تأشيرات العمرة',
        theme: AppTheme.lightTheme.copyWith(
          // Use car icon from corporation_no_icon
          appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
            leading: Icon(CorporationNoIcon.car),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
        locale: Locale('ar', 'SA'),
        supportedLocales: [
          Locale('ar', 'SA'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}