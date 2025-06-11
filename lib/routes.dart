import 'package:flutter/material.dart';
import 'screens.dart';
import 'models.dart';
import 'core.dart';

// routes/app_routes.dart
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
        final client = settings.arguments as ClientModel?;
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
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
        );

      case '/admin/user_clients':
        final user = settings.arguments as UserModel;
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
        final client = settings.arguments as ClientModel?;
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(client: client),
        );

      case '/user/manage_clients':
        return MaterialPageRoute(builder: (_) => UserClientManagementScreen());

      case '/user/notifications':
        return MaterialPageRoute(builder: (_) => UserNotificationsScreen());

      case '/user/settings':
        return MaterialPageRoute(builder: (_) => UserSettingsScreen());

      case '/view_images':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ImageViewer(
            imageUrls: args['imageUrls'] as List<String>,
            initialIndex: args['initialIndex'] as int? ?? 0,
          ),
        );

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