import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'controllers.dart';
import 'routes.dart';
import 'models.dart';
import 'core.dart';
import 'services.dart';
import 'app_initialization_service.dart';
import 'error_handler.dart';
import 'network_utils.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for this app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Initialize the app using the initialization service
    await AppInitializationService.initialize();

    print('✅ App initialization completed successfully');

    // Run the app
    runApp(PassengersApp());

  } catch (error, stackTrace) {
    print('❌ Critical initialization error: $error');
    print('Stack trace: $stackTrace');

    // Run a minimal error app
    runApp(ErrorApp(error: error));
  }
}

class PassengersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider(
          create: (_) => ClientController(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserController(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: AppTheme.lightTheme,

            // Localization
            locale: Locale('ar', 'SA'),
            supportedLocales: [
              Locale('ar', 'SA'),
              Locale('en', 'US'), // Fallback locale
            ],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Text direction for RTL
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? Container(),
              );
            },

            // Navigation
            initialRoute: _getInitialRoute(authController),
            onGenerateRoute: AppRoutes.generateRoute,

            // Error handling
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => NotFoundScreen(),
              );
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute(AuthController authController) {
    // If user is logged in, navigate to appropriate dashboard
    if (authController.isLoggedIn) {
      final user = authController.currentUser!;
      switch (user.role) {
        case UserRole.admin:
          return RouteConstants.adminDashboard;
        case UserRole.user:
        case UserRole.agency:
          return RouteConstants.userDashboard;
      }
    }

    // Default to login screen
    return RouteConstants.login;
  }
}

// Error app to show when critical initialization fails
class ErrorApp extends StatelessWidget {
  final dynamic error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خطأ في التطبيق',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto', // Fallback font
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                SizedBox(height: 24),
                Text(
                  'فشل في تشغيل التطبيق',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  ErrorHandler.getArabicErrorMessage(error),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart the app
                    SystemNavigator.pop();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('إعادة تشغيل التطبيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Copy error to clipboard
                    Clipboard.setData(ClipboardData(text: error.toString()));
                  },
                  child: Text(
                    'نسخ تفاصيل الخطأ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة غير موجودة'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 24),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'الصفحة المطلوبة غير موجودة',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteConstants.login,
                        (route) => false,
                  );
                },
                icon: Icon(Icons.home),
                label: Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// App lifecycle observer for handling app state changes
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed');
        // App is in foreground
        StatusUpdateService.startAutoStatusUpdate();
        BackgroundService.startBackgroundTasks();
        break;

      case AppLifecycleState.paused:
        print('📱 App paused');
        // App is in background
        break;

      case AppLifecycleState.detached:
        print('📱 App detached');
        // Clean up resources
        StatusUpdateService.stopAutoStatusUpdate();
        BackgroundService.stopBackgroundTasks();
        NetworkUtils.dispose();
        break;

      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;

      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }
}

// Initialize app lifecycle observer
class AppWithLifecycle extends StatefulWidget {
  final Widget child;

  const AppWithLifecycle({Key? key, required this.child}) : super(key: key);

  @override
  State<AppWithLifecycle> createState() => _AppWithLifecycleState();
}

class _AppWithLifecycleState extends State<AppWithLifecycle> {
  late AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = AppLifecycleObserver();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}