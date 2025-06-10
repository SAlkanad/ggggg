import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/user/user_dashboard.dart';
import '../screens/admin/client_form_screen.dart';
import '../screens/user/user_client_form_screen.dart';
import '../screens/admin/client_management_screen.dart';
import '../screens/user/user_client_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/user_form_screen.dart';
import '../screens/admin/user_clients_screen.dart';
import '../screens/admin/admin_notifications_screen.dart';
import '../screens/user/user_notifications_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/user/user_settings_screen.dart';
import '../models/client_model.dart'; // Import ClientModel
import '../models/user_model.dart'; // Import UserModel


class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboard());
      
      case '/user_dashboard':
        return MaterialPageRoute(builder: (_) => UserDashboard());
      
      case '/admin/add_client':
        return MaterialPageRoute(builder: (_) => ClientFormScreen());
      
      case '/admin/edit_client':
        final client = settings.arguments as ClientModel?; // Explicit cast
        return MaterialPageRoute(
          builder: (_) => ClientFormScreen(client: client),
        );
      
      case '/admin/manage_clients':
        return MaterialPageRoute(builder: (_) => ClientManagementScreen());
      
      case '/admin/manage_users':
        return MaterialPageRoute(builder: (_) => UserManagementScreen());
      
      case '/admin/add_user':
        return MaterialPageRoute(builder: (_) => UserFormScreen());
      
      case '/admin/edit_user':
        final user = settings.arguments as UserModel?; // Explicit cast
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
        );
      
      case '/admin/user_clients':
        final user = settings.arguments as UserModel; // Explicit cast (assuming it's never null here)
        return MaterialPageRoute(
          builder: (_) => UserClientsScreen(user: user),
        );
      
      case '/admin/notifications':
        return MaterialPageRoute(builder: (_) => AdminNotificationsScreen());
      
      case '/admin/settings':
        return MaterialPageRoute(builder: (_) => AdminSettingsScreen());
      
      case '/user/add_client':
        return MaterialPageRoute(builder: (_) => UserClientFormScreen());
      
      case '/user/edit_client':
        final client = settings.arguments as ClientModel?; // Explicit cast
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(client: client),
        );
      
      case '/user/manage_clients':
        return MaterialPageRoute(builder: (_) => UserClientManagementScreen());
      
      case '/user/notifications':
        return MaterialPageRoute(builder: (_) => UserNotificationsScreen());
      
      case '/user/settings':
        return MaterialPageRoute(builder: (_) => UserSettingsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة'),
            ),
          ),
        );
    }
  }
}