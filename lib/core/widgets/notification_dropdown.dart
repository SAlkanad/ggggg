import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/notification_model.dart';
import '../utils/date_utils.dart';

class NotificationDropdown extends StatefulWidget {
  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown> {
  bool _isOpen = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser != null) {
      Provider.of<NotificationController>(context, listen: false)
          .loadNotifications(
            authController.currentUser!.id, 
            isAdmin: authController.currentUser!.role.toString() == 'UserRole.admin'
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
      builder: (context, notificationController, child) {
        final unreadCount = notificationController.getUnreadCount();
        
        return PopupMenuButton<String>(
          icon: Stack(
            children: [
              Icon(Icons.notifications),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onOpened: () {
            setState(() => _isOpen = true);
            if (unreadCount > 0) {
              _playNotificationSound();
            }
          },
          onCanceled: () => setState(() => _isOpen = false),
          offset: Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 350,
            height: 400,
            child: _buildNotificationsList(notificationController),
          ),
          itemBuilder: (context) => [],
        );
      },
    );
  }

  Widget _buildNotificationsList(NotificationController controller) {
    if (controller.isLoading) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final notifications = controller.notifications.take(10).toList();

    if (notifications.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإشعارات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _markAllAsRead(controller),
                  child: Text('تحديد الكل كمقروء'),
                ),
              ],
            ),
          ),
          Divider(),
          
          // Notifications list
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification, controller);
              },
            ),
          ),
          
          // Footer
          Container(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _viewAllNotifications(),
                child: Text('عرض جميع الإشعارات'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, NotificationController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: notification.isRead ? null : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getPriorityColor(notification.priority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getPriorityColor(notification.priority),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              formatTimeAgo(notification.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification, controller),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.clientExpiring:
        return Icons.person_off;
      case NotificationType.userValidationExpiring:
        return Icons.account_circle_outlined;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  void _playNotificationSound() {
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Fallback to vibration if sound fails
      HapticFeedback.mediumImpact();
    }
  }

  void _handleNotificationTap(NotificationModel notification, NotificationController controller) async {
    // Mark as read
    if (!notification.isRead) {
      await controller.markAsRead(notification.id);
    }

    // Navigate to relevant screen
    if (notification.type == NotificationType.clientExpiring) {
      Navigator.pushNamed(context, '/admin/manage_clients');
    } else if (notification.type == NotificationType.userValidationExpiring) {
      Navigator.pushNamed(context, '/admin/manage_users');
    }
  }

  void _markAllAsRead(NotificationController controller) async {
    try {
      final unreadNotifications = controller.getUnreadNotifications();
      for (final notification in unreadNotifications) {
        await controller.markAsRead(notification.id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الإشعارات')),
      );
    }
  }

  void _viewAllNotifications() {
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser?.role.toString() == 'UserRole.admin') {
      Navigator.pushNamed(context, '/admin/notifications');
    } else {
      Navigator.pushNamed(context, '/user/notifications');
    }
  }
}