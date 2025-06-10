import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:local_auth/local_auth.dart';

import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/client_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/settings_controller.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/status_update_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/user/user_dashboard.dart';
import 'models/user_model.dart';

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
        title: 'نظام إدارة المسافرين',
        theme: AppTheme.lightTheme,
        home: SplashScreen(),
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

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Try auto-login
    await authController.initializeAuth();
    
    // Navigate based on login status
    if (authController.isLoggedIn) {
      final user = authController.currentUser!;
      _navigateToHome(user);
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome(UserModel user) {
    switch (user.role) {
      case UserRole.admin:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
        break;
      case UserRole.user:
      case UserRole.agency:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserDashboard()),
        );
        break;
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 32),
                
                // App Title
                Text(
                  'نظام إدارة المسافرين',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                
                Text(
                  'إدارة شاملة لتأشيرات العملاء',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 48),
                
                // Loading indicator
                if (authController.isAutoLoading)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'دخول',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}