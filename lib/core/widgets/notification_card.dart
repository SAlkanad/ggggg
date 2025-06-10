import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../utils/date_utils.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
    this.onWhatsApp,
    this.onCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getNotificationIcon(),
                  color: _getPriorityColor(),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: notification.isRead ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: notification.isRead ? Colors.grey : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  formatTimeAgo(notification.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Spacer(),
                if (onWhatsApp != null)
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.green, size: 20),
                    onPressed: onWhatsApp,
                    tooltip: 'إرسال واتساب',
                  ),
                if (onCall != null)
                  IconButton(
                    icon: Icon(Icons.call, color: Colors.blue, size: 20),
                    onPressed: onCall,
                    tooltip: 'اتصال',
                  ),
                if (!notification.isRead && onMarkAsRead != null)
                  IconButton(
                    icon: Icon(Icons.mark_email_read, color: Colors.orange, size: 20),
                    onPressed: onMarkAsRead,
                    tooltip: 'تحديد كمقروء',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.clientExpiring:
        return Icons.person_off;
      case NotificationType.userValidationExpiring:
  return Icons.account_circle_outlined;
    }
  }

  Color _getPriorityColor() {
    switch (notification.priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
    }
  }
}
