import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../utils/date_utils.dart' as AppDateUtils;

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
                'ينتهي في: ${AppDateUtils.formatArabicDate(user.validationEndDate!)}',
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