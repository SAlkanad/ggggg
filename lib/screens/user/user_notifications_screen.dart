import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/client_controller.dart';
import '../../core/widgets/notification_card.dart';
import '../../models/notification_model.dart';

class UserNotificationsScreen extends StatefulWidget {
  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<NotificationController>(context, listen: false)
          .loadNotifications(authController.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshNotifications(),
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, notificationController, child) {
          if (notificationController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (notificationController.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد إشعارات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notificationController.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationController.notifications[index];
              return NotificationCard(
                notification: notification,
                onMarkAsRead: () => _markAsRead(notificationController, notification.id),
                onWhatsApp: notification.type == NotificationType.clientExpiring
                    ? () => _sendWhatsAppToClient(notification)
                    : null,
                onCall: notification.type == NotificationType.clientExpiring
                    ? () => _callClient(notification)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _refreshNotifications() {
    final authController = Provider.of<AuthController>(context, listen: false);
    Provider.of<NotificationController>(context, listen: false)
        .loadNotifications(authController.currentUser!.id);
  }

  void _markAsRead(NotificationController controller, String notificationId) async {
    try {
      await controller.markAsRead(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الإشعار: ${e.toString()}')),
      );
    }
  }

  void _sendWhatsAppToClient(NotificationModel notification) async {
    if (notification.clientId == null) return;
    
    try {
      final clientController = Provider.of<ClientController>(context, listen: false);
      final client = clientController.clients.firstWhere((c) => c.id == notification.clientId);
      
      await Provider.of<NotificationController>(context, listen: false)
          .sendWhatsAppToClient(client, notification.message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إرسال الواتساب: ${e.toString()}')),
      );
    }
  }

  void _callClient(NotificationModel notification) async {
    if (notification.clientId == null) return;
    
    try {
      final clientController = Provider.of<ClientController>(context, listen: false);
      final client = clientController.clients.firstWhere((c) => c.id == notification.clientId);
      
      await Provider.of<NotificationController>(context, listen: false)
          .callClient(client);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المكالمة: ${e.toString()}')),
      );
    }
  }
}
