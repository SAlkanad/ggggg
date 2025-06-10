import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/widgets/notification_card.dart';
import '../../models/notification_model.dart';

class AdminNotificationsScreen extends StatefulWidget {
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<NotificationController>(context, listen: false)
          .loadNotifications(authController.currentUser!.id, isAdmin: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'إشعارات العملاء'),
            Tab(text: 'إشعارات المستخدمين'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshNotifications(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientNotifications(),
          _buildUserNotifications(),
        ],
      ),
    );
  }

  Widget _buildClientNotifications() {
    return Consumer<NotificationController>(
      builder: (context, notificationController, child) {
        if (notificationController.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final clientNotifications = notificationController.notifications
            .where((n) => n.type == NotificationType.clientExpiring)
            .toList();

        if (clientNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد إشعارات للعملاء', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: clientNotifications.length,
          itemBuilder: (context, index) {
            final notification = clientNotifications[index];
            return NotificationCard(
              notification: notification,
              onMarkAsRead: () => _markAsRead(notificationController, notification.id),
              onWhatsApp: () => _sendWhatsAppToClient(notification),
              onCall: () => _callClient(notification),
            );
          },
        );
      },
    );
  }

  Widget _buildUserNotifications() {
    return Consumer<NotificationController>(
      builder: (context, notificationController, child) {
        if (notificationController.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final userNotifications = notificationController.notifications
            .where((n) => n.type == NotificationType.userValidationExpiring)
            .toList();

        if (userNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد إشعارات للمستخدمين', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: userNotifications.length,
          itemBuilder: (context, index) {
            final notification = userNotifications[index];
            return NotificationCard(
              notification: notification,
              onMarkAsRead: () => _markAsRead(notificationController, notification.id),
              onWhatsApp: () => _sendWhatsAppToUser(notification),
              onCall: () => _callUser(notification),
            );
          },
        );
      },
    );
  }

  void _refreshNotifications() {
    final authController = Provider.of<AuthController>(context, listen: false);
    Provider.of<NotificationController>(context, listen: false)
        .loadNotifications(authController.currentUser!.id, isAdmin: true);
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

  void _sendWhatsAppToUser(NotificationModel notification) async {
    try {
      final userController = Provider.of<UserController>(context, listen: false);
      final user = userController.users.firstWhere((u) => u.id == notification.targetUserId);
      
      await Provider.of<NotificationController>(context, listen: false)
          .sendWhatsAppToUser(user, notification.message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إرسال الواتساب: ${e.toString()}')),
      );
    }
  }

  void _callUser(NotificationModel notification) async {
    try {
      final userController = Provider.of<UserController>(context, listen: false);
      final user = userController.users.firstWhere((u) => u.id == notification.targetUserId);
      
      await Provider.of<NotificationController>(context, listen: false)
          .sendWhatsAppToUser(user, notification.message); // For now, same as WhatsApp
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المكالمة: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
