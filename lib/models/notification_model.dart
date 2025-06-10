enum NotificationType { clientExpiring, userValidationExpiring }
enum NotificationPriority { high, medium, low }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String targetUserId;
  final String? clientId;
  final bool isRead;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.targetUserId,
    this.clientId,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
    required this.createdAt,
    this.scheduledFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'targetUserId': targetUserId,
      'clientId': clientId,
      'isRead': isRead,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'scheduledFor': scheduledFor?.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.clientExpiring,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      clientId: map['clientId'],
      isRead: map['isRead'] ?? false,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      scheduledFor: map['scheduledFor'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledFor'])
          : null,
    );
  }
}
