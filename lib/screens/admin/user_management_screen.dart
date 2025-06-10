import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/user_card.dart';
import '../../models/user_model.dart';
import 'user_form_screen.dart';
import 'user_clients_screen.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserController>(context, listen: false).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _addUser(),
          ),
          IconButton(
            icon: Icon(Icons.notification_add),
            onPressed: () => _sendNotificationDialog(),
          ),
        ],
      ),
      body: Consumer<UserController>(
        builder: (context, userController, child) {
          if (userController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (userController.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد مستخدمون مسجلون', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addUser,
                    icon: Icon(Icons.person_add),
                    label: Text('إضافة مستخدم جديد'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: userController.users.length,
            itemBuilder: (context, index) {
              final user = userController.users[index];
              return UserCard(
                user: user,
                onEdit: () => _editUser(user),
                onDelete: () => _deleteUser(userController, user.id),
                onFreeze: () => _freezeUserDialog(userController, user),
                onUnfreeze: () => _unfreezeUser(userController, user.id),
                onSetValidation: () => _setValidationDialog(userController, user),
                onViewClients: () => _viewUserClients(user),
                onSendNotification: () => _sendUserNotificationDialog(userController, user),
              );
            },
          );
        },
      ),
    );
  }

  void _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserFormScreen()),
    );
    if (result == true) {
      Provider.of<UserController>(context, listen: false).loadUsers();
    }
  }

  void _editUser(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserFormScreen(user: user)),
    );
    if (result == true) {
      Provider.of<UserController>(context, listen: false).loadUsers();
    }
  }

  void _deleteUser(UserController controller, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا المستخدم؟ سيتم حذف جميع عملائه أيضاً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف المستخدم بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف المستخدم: ${e.toString()}')),
        );
      }
    }
  }

  void _freezeUserDialog(UserController controller, UserModel user) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تجميد المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سبب التجميد:'),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'أدخل سبب التجميد',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                try {
                  await controller.freezeUser(user.id, reasonController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تجميد المستخدم')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في التجميد: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('تجميد'),
          ),
        ],
      ),
    );
  }

  void _unfreezeUser(UserController controller, String userId) async {
    try {
      await controller.unfreezeUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إلغاء تجميد المستخدم')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إلغاء التجميد: ${e.toString()}')),
      );
    }
  }

  void _setValidationDialog(UserController controller, UserModel user) {
    DateTime selectedDate = user.validationEndDate ?? DateTime.now().add(Duration(days: 30));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('تحديد صلاحية الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تاريخ انتهاء الصلاحية:'),
              SizedBox(height: 16),
              ListTile(
                title: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await controller.setUserValidation(user.id, selectedDate);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تحديث صلاحية الحساب')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في التحديث: ${e.toString()}')),
                  );
                }
              },
              child: Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewUserClients(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserClientsScreen(user: user),
      ),
    );
  }

  void _sendUserNotificationDialog(UserController controller, UserModel user) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال إشعار للمستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المستخدم: ${user.name}'),
            SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'اكتب الرسالة',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                try {
                  await controller.sendNotificationToUser(user.id, messageController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إرسال الإشعار')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الإرسال: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _sendNotificationDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال إشعار لجميع المستخدمين'),
        content: TextField(
          controller: messageController,
          decoration: InputDecoration(
            hintText: 'اكتب الرسالة',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                try {
                  await Provider.of<UserController>(context, listen: false)
                      .sendNotificationToAllUsers(messageController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إرسال الإشعار لجميع المستخدمين')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الإرسال: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('إرسال للجميع'),
          ),
        ],
      ),
    );
  }
}
