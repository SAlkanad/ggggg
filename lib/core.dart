import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:ui' as ui;
import 'models.dart';
import 'services.dart';

class AppConstants {
  static const String appName = 'نظام إدارة تأشيرات العمرة';
  static const String appVersion = '1.0.0';

  static const int defaultGreenDays = 30;
  static const int defaultYellowDays = 30;
  static const int defaultRedDays = 1;

  static const int firstTierDays = 10;
  static const int firstTierFrequency = 2;
  static const int secondTierDays = 5;
  static const int secondTierFrequency = 4;
  static const int thirdTierDays = 2;
  static const int thirdTierFrequency = 8;

  static const int userFirstTierFreq = 1;
  static const int userSecondTierFreq = 1;
  static const int userThirdTierFreq = 1;

  static const String defaultClientMessage = 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.';
  static const String defaultUserMessage = 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.';
}

class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String clientsCollection = 'clients';
  static const String notificationsCollection = 'notifications';
  static const String adminSettingsCollection = 'adminSettings';
  static const String userSettingsCollection = 'userSettings';
  static const String imagesStorage = 'images';
}

class RouteConstants {
  static const String login = '/';
  static const String adminDashboard = '/admin_dashboard';
  static const String userDashboard = '/user_dashboard';
  static const String adminAddClient = '/admin/add_client';
  static const String adminManageClients = '/admin/manage_clients';
  static const String adminManageUsers = '/admin/manage_users';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';
  static const String userAddClient = '/user/add_client';
  static const String userManageClients = '/user/manage_clients';
  static const String userNotifications = '/user/notifications';
  static const String userSettings = '/user/settings';
}

class MessageTemplates {
  static const Map<String, String> clientMessages = {
    'tier1': 'تنبيه: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. يرجى التواصل معنا.',
    'tier2': 'تحذير: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. يرجى التواصل معنا فوراً.',
    'tier3': 'عاجل: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. اتصل بنا على الفور.',
    'expired': 'عزيزي العميل {clientName}، انتهت صلاحية تأشيرتك. يجب مراجعتنا فوراً.',
  };

  static const Map<String, String> userMessages = {
    'tier1': 'تنبيه: ينتهي حسابك خلال {daysRemaining} أيام. يرجى التجديد.',
    'tier2': 'تحذير: ينتهي حسابك خلال {daysRemaining} أيام. يرجى التجديد فوراً.',
    'tier3': 'عاجل: ينتهي حسابك خلال {daysRemaining} أيام. يجب التجديد فوراً.',
    'validation_expired': 'انتهت صلاحية حسابك. تم تجميد الحساب.',
    'freeze_notification': 'تم تجميد حسابك. السبب: {reason}',
    'unfreeze_notification': 'تم إلغاء تجميد حسابك. يمكنك الآن استخدام النظام.',
  };

  static const Map<String, String> whatsappMessages = {
    'client_default': 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.',
    'client_urgent': 'عاجل: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام.',
    'user_default': 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.',
    'admin_broadcast': 'إشعار عام من إدارة النظام: {message}',
  };

  static String formatMessage(String template, Map<String, String> variables) {
    String formatted = template;
    variables.forEach((key, value) {
      formatted = formatted.replaceAll('{$key}', value);
    });
    return formatted;
  }
}

String formatArabicDate(DateTime date) {
  try {
    final formatter = DateFormat('yyyy/MM/dd', 'ar');
    return formatter.format(date);
  } catch (e) {
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
  }
}

String formatTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return 'منذ ${difference.inDays} يوم';
  } else if (difference.inHours > 0) {
    return 'منذ ${difference.inHours} ساعة';
  } else if (difference.inMinutes > 0) {
    return 'منذ ${difference.inMinutes} دقيقة';
  } else {
    return 'الآن';
  }
}

class ValidationUtils {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateClientPhone(String? value, PhoneCountry country) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف الأساسي مطلوب';
    }

    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (country == PhoneCountry.saudi) {
      if (!RegExp(r'^(5)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم سعودي غير صحيح (يجب أن يبدأ بـ 5 ويكون 9 أرقام)';
      }
    } else if (country == PhoneCountry.yemen) {
      if (!RegExp(r'^(7)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم يمني غير صحيح (يجب أن يبدأ بـ 7 ويكون 9 أرقام)';
      }
    }

    return null;
  }

  static String? validateSecondPhone(String? value, PhoneCountry country) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (country == PhoneCountry.saudi) {
      if (!RegExp(r'^(5)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم سعودي غير صحيح (يجب أن يبدأ بـ 5 ويكون 9 أرقام)';
      }
    } else if (country == PhoneCountry.yemen) {
      if (!RegExp(r'^(7)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم يمني غير صحيح (يجب أن يبدأ بـ 7 ويكون 9 أرقام)';
      }
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }
}

class StatusCalculator {
  static ClientStatus calculateStatus(DateTime entryDate, {
    int greenDays = 30,
    int yellowDays = 30,
    int redDays = 1,
  }) {
    final daysRemaining = calculateDaysRemaining(entryDate);

    if (daysRemaining > greenDays) {
      return ClientStatus.green;
    } else if (daysRemaining > redDays) {
      return ClientStatus.yellow;
    } else if (daysRemaining >= 0) {
      return ClientStatus.red;
    } else {
      return ClientStatus.red;
    }
  }

  static int calculateDaysRemaining(DateTime entryDate) {
    final now = DateTime.now();
    final visaExpiry = entryDate.add(Duration(days: 90));
    return visaExpiry.difference(now).inDays;
  }

  static String getStatusText(ClientStatus status) {
    switch (status) {
      case ClientStatus.green:
        return 'آمن';
      case ClientStatus.yellow:
        return 'تحذير';
      case ClientStatus.red:
        return 'خطر';
      case ClientStatus.white:
        return 'خرج';
    }
  }

  static Color getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.green:
        return Colors.green;
      case ClientStatus.yellow:
        return Colors.orange;
      case ClientStatus.red:
        return Colors.red;
      case ClientStatus.white:
        return Colors.grey;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Cairo',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

abstract class BaseFormScreen extends StatefulWidget {
  const BaseFormScreen({Key? key}) : super(key: key);
}

abstract class BaseFormScreenState<T extends BaseFormScreen> extends State<T> {
  final List<TextEditingController> _controllers = [];
  bool _isLoading = false;

  void registerController(TextEditingController controller) {
    _controllers.add(controller);
  }

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  bool get isLoading => _isLoading;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      enabled: widget.enabled,
      textDirection: ui.TextDirection.rtl,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon != null ? Icon(widget.icon!) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class StatusCard extends StatelessWidget {
  final ClientStatus status;
  final int daysRemaining;

  const StatusCard({
    Key? key,
    required this.status,
    required this.daysRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = StatusCalculator.getStatusColor(status);
    String text = StatusCalculator.getStatusText(status);
    IconData icon;

    switch (status) {
      case ClientStatus.green:
        icon = Icons.check_circle;
        break;
      case ClientStatus.yellow:
        icon = Icons.warning;
        break;
      case ClientStatus.red:
        icon = Icons.error;
        break;
      case ClientStatus.white:
        icon = Icons.flight_takeoff;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            status == ClientStatus.white ? text : '$text ($daysRemaining يوم)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onFreeze;
  final VoidCallback? onUnfreeze;
  final VoidCallback? onSetValidation;
  final VoidCallback? onViewClients;
  final VoidCallback? onSendNotification;

  const UserCard({
    Key? key,
    required this.user,
    this.onEdit,
    this.onDelete,
    this.onFreeze,
    this.onUnfreeze,
    this.onSetValidation,
    this.onViewClients,
    this.onSendNotification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getUserStatusColor(),
                  child: Icon(
                    _getUserIcon(),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${user.username}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.person, _getRoleText()),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.phone, user.phone),
                ),
              ],
            ),

            if (user.email.isNotEmpty) ...[
              SizedBox(height: 8),
              _buildInfoItem(Icons.email, user.email),
            ],

            if (user.validationEndDate != null) ...[
              SizedBox(height: 8),
              _buildInfoItem(
                Icons.calendar_today,
                'ينتهي في: ${formatArabicDate(user.validationEndDate!)}',
                color: _getValidationColor(),
              ),
            ],

            if (user.isFrozen && user.freezeReason != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مجمد: ${user.freezeReason}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12),
            Row(
              children: [
                if (onViewClients != null)
                  IconButton(
                    icon: Icon(Icons.people, color: Colors.blue),
                    onPressed: onViewClients,
                    tooltip: 'عرض العملاء',
                  ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: onEdit,
                    tooltip: 'تعديل',
                  ),
                if (onSetValidation != null)
                  IconButton(
                    icon: Icon(Icons.date_range, color: Colors.green),
                    onPressed: onSetValidation,
                    tooltip: 'تحديد الصلاحية',
                  ),
                if (!user.isFrozen && onFreeze != null)
                  IconButton(
                    icon: Icon(Icons.block, color: Colors.red),
                    onPressed: onFreeze,
                    tooltip: 'تجميد',
                  ),
                if (user.isFrozen && onUnfreeze != null)
                  IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onUnfreeze,
                    tooltip: 'إلغاء التجميد',
                  ),
                if (onSendNotification != null)
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.purple),
                    onPressed: onSendNotification,
                    tooltip: 'إرسال إشعار',
                  ),
                Spacer(),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'حذف',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    String text;
    Color color;

    if (user.isFrozen) {
      text = 'مجمد';
      color = Colors.red;
    } else if (!user.isActive) {
      text = 'غير مفعل';
      color = Colors.grey;
    } else if (user.validationEndDate != null && user.validationEndDate!.isBefore(DateTime.now())) {
      text = 'منتهي الصلاحية';
      color = Colors.orange;
    } else {
      text = 'نشط';
      color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getUserStatusColor() {
    if (user.isFrozen) return Colors.red;
    if (!user.isActive) return Colors.grey;
    if (user.validationEndDate != null && user.validationEndDate!.isBefore(DateTime.now())) {
      return Colors.orange;
    }
    return Colors.green;
  }

  IconData _getUserIcon() {
    switch (user.role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.agency:
        return Icons.business;
      case UserRole.user:
        return Icons.person;
    }
  }

  String _getRoleText() {
    switch (user.role) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.agency:
        return 'وكالة';
      case UserRole.user:
        return 'مستخدم';
    }
  }

  Color _getValidationColor() {
    if (user.validationEndDate == null) return Colors.grey;

    final daysRemaining = user.validationEndDate!.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) return Colors.red;
    if (daysRemaining <= 5) return Colors.orange;
    if (daysRemaining <= 15) return Colors.yellow[700]!;
    return Colors.green;
  }
}

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(ClientStatus)? onStatusChange;
  final VoidCallback? onViewImages;
  final String? createdByName;

  const ClientCard({
    Key? key,
    required this.client,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.onViewImages,
    this.createdByName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.clientName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (createdByName != null) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'بواسطة: $createdByName',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusCard(
                  status: client.status,
                  daysRemaining: client.daysRemaining,
                ),
              ],
            ),
            SizedBox(height: 8),
            if (client.clientPhone.isNotEmpty)
              _buildPhoneSection(context),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.card_membership, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('نوع التأشيرة: ${_getVisaTypeText(client.visaType)}'),
              ],
            ),
            if (client.agentName != null && client.agentName!.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.support_agent, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('الوكيل: ${client.agentName}'),
                ],
              ),
            ],
            if (client.imageUrls.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.image, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('${client.imageUrls.length} صورة مرفقة'),
                  SizedBox(width: 8),
                  if (onViewImages != null)
                    GestureDetector(
                      onTap: onViewImages,
                      child: Text(
                        'عرض الصور',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _downloadImages(context),
                    child: Text(
                      'تحميل الصور',
                      style: TextStyle(
                        color: Colors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                if (!client.hasExited && client.clientPhone.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.green),
                    onPressed: () => _sendWhatsApp(context),
                    tooltip: 'إرسال واتساب',
                  ),
                  IconButton(
                    icon: Icon(Icons.call, color: Colors.blue),
                    onPressed: () => _makeCall(client.clientPhone),
                    tooltip: 'اتصال',
                  ),
                ],
                if (!client.hasExited && client.secondPhone != null && client.secondPhone!.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.call_outlined, color: Colors.blue.shade300),
                    onPressed: () => _makeCall(client.secondPhone!),
                    tooltip: 'اتصال - رقم ثانوي',
                  ),
                Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: onEdit,
                    tooltip: 'تعديل',
                  ),
                if (onStatusChange != null && !client.hasExited)
                  IconButton(
                    icon: Icon(Icons.exit_to_app, color: Colors.grey),
                    onPressed: () => onStatusChange!(ClientStatus.white),
                    tooltip: 'تحديد كخارج',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'حذف',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text('رقم أساسي: ${client.clientPhone}'),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                client.phoneCountry == PhoneCountry.saudi ? 'SA' : 'YE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (client.secondPhone != null && client.secondPhone!.isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_android, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text('رقم ثانوي: ${client.secondPhone}'),
            ],
          ),
        ],
      ],
    );
  }

  String _getVisaTypeText(VisaType type) {
    switch (type) {
      case VisaType.visit:
        return 'زيارة';
      case VisaType.work:
        return 'عمل';
      case VisaType.umrah:
        return 'عمرة';
      case VisaType.hajj:
        return 'حج';
    }
  }

  void _sendWhatsApp(BuildContext context) async {
    try {
      await WhatsAppService.sendClientMessage(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
        message: 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.',
        clientName: client.clientName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في فتح الواتساب: ${e.toString()}')),
      );
    }
  }

  void _makeCall(String phoneNumber) async {
    try {
      await WhatsAppService.callClient(
        phoneNumber: phoneNumber,
        country: client.phoneCountry,
      );
    } catch (e) {
    }
  }

  void _downloadImages(BuildContext context) async {
    try {
      for (String imageUrl in client.imageUrls) {
        await ImageService.downloadImage(imageUrl);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم فتح الصور للتحميل')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصور')),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا العميل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? clientName;

  const ImageViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.clientName,
  }) : super(key: key);

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصور المرفقة (${_currentIndex + 1}/${widget.imageUrls.length})'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadImage(context, widget.imageUrls[_currentIndex]),
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () => _openImageInBrowser(context, widget.imageUrls[_currentIndex]),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: GestureDetector(
              onTap: () => _downloadImage(context, widget.imageUrls[index]),
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                placeholder: (context, url) => SpinKitFadingCircle(
                  color: Colors.white,
                  size: 50.0,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 50,
                ),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  void _downloadImage(BuildContext context, String imageUrl) async {
    try {
      await ImageService.downloadImage(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم فتح الصورة للتحميل')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصورة')),
      );
    }
  }

  void _openImageInBrowser(BuildContext context, String imageUrl) async {
    try {
      await ImageService.openImageInBrowser(imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في فتح الصورة')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ClientFilter currentFilter;
  final List<UserModel> users;
  final Function(ClientFilter) onApplyFilter;

  const FilterBottomSheet({
    Key? key,
    required this.currentFilter,
    required this.users,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ClientFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'تصفية العملاء',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempFilter = ClientFilter();
                  });
                },
                child: Text('مسح الكل'),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (widget.users.isNotEmpty) ...[
            Text('تصفية حسب المستخدم:', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tempFilter.userFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'اختر المستخدم',
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text('جميع المستخدمين')),
                ...widget.users.map((user) => DropdownMenuItem<String>(
                  value: user.id,
                  child: Text(user.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _tempFilter = _tempFilter.copyWith(userFilter: value);
                });
              },
            ),
            SizedBox(height: 16),
          ],

          Text('تصفية حسب الحالة:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          DropdownButtonFormField<ClientStatus>(
            value: _tempFilter.statusFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اختر الحالة',
            ),
            items: [
              DropdownMenuItem<ClientStatus>(value: null, child: Text('جميع الحالات')),
              DropdownMenuItem<ClientStatus>(value: ClientStatus.green, child: Text('آمن')),
              DropdownMenuItem<ClientStatus>(value: ClientStatus.yellow, child: Text('تحذير')),
              DropdownMenuItem<ClientStatus>(value: ClientStatus.red, child: Text('خطر')),
              DropdownMenuItem<ClientStatus>(value: ClientStatus.white, child: Text('خرج')),
            ],
            onChanged: (value) {
              setState(() {
                _tempFilter = _tempFilter.copyWith(statusFilter: value);
              });
            },
          ),
          SizedBox(height: 16),

          Text('تصفية حسب نوع التأشيرة:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          DropdownButtonFormField<VisaType>(
            value: _tempFilter.visaTypeFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اختر نوع التأشيرة',
            ),
            items: [
              DropdownMenuItem<VisaType>(value: null, child: Text('جميع الأنواع')),
              DropdownMenuItem<VisaType>(value: VisaType.visit, child: Text('زيارة')),
              DropdownMenuItem<VisaType>(value: VisaType.work, child: Text('عمل')),
              DropdownMenuItem<VisaType>(value: VisaType.umrah, child: Text('عمرة')),
              DropdownMenuItem<VisaType>(value: VisaType.hajj, child: Text('حج')),
            ],
            onChanged: (value) {
              setState(() {
                _tempFilter = _tempFilter.copyWith(visaTypeFilter: value);
              });
            },
          ),
          SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilter(_tempFilter);
                    Navigator.pop(context);
                  },
                  child: Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationDropdown extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onViewAll;

  const NotificationDropdown({
    Key? key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

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
                  '$unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        if (notifications.isEmpty) {
          return [
            PopupMenuItem<String>(
              value: 'empty',
              child: Text('لا توجد إشعارات'),
            ),
          ];
        }

        final recentNotifications = notifications.take(5).toList();

        return [
          ...recentNotifications.map((notification) => PopupMenuItem<String>(
            value: notification.id,
            child: Container(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    formatTimeAgo(notification.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'view_all',
            child: Row(
              children: [
                Icon(Icons.list, size: 16),
                SizedBox(width: 8),
                Text('عرض جميع الإشعارات'),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 'view_all') {
          onViewAll();
        } else if (value != 'empty') {
          onMarkAsRead(value);
        }
      },
    );
  }
}