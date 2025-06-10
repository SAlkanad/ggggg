import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validation_utils.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({Key? key, this.user}) : super(key: key);

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  UserRole _role = UserRole.user;
  DateTime _validationEndDate = DateTime.now().add(Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final user = widget.user!;
    _usernameController.text = user.username;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    _role = user.role;
    _validationEndDate = user.validationEndDate ?? DateTime.now().add(Duration(days: 30));
    _isActive = user.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _usernameController,
                label: 'اسم المستخدم *',
                icon: Icons.person,
                validator: ValidationUtils.validateUsername,
                enabled: widget.user == null, // Can't edit username of existing user
              ),
              SizedBox(height: 16),

              if (widget.user == null) ...[
                CustomTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور *',
                  icon: Icons.lock,
                  isPassword: true,
                  validator: ValidationUtils.validatePassword,
                ),
                SizedBox(height: 16),
              ],

              CustomTextField(
                controller: _nameController,
                label: 'الاسم الكامل *',
                icon: Icons.account_circle,
                validator: ValidationUtils.validateRequired,
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'رقم الهاتف *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: ValidationUtils.validateRequired,
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: ValidationUtils.validateEmail,
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'نوع المستخدم *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: [
                  DropdownMenuItem(value: UserRole.user, child: Text('مستخدم')),
                  DropdownMenuItem(value: UserRole.agency, child: Text('وكالة')),
                ],
                onChanged: (value) => setState(() => _role = value!),
                validator: (value) => value == null ? 'اختر نوع المستخدم' : null,
              ),
              SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صلاحية الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ListTile(
                        title: Text('تاريخ انتهاء الصلاحية'),
                        subtitle: Text('${_validationEndDate.day}/${_validationEndDate.month}/${_validationEndDate.year}'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: _selectValidationDate,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              SwitchListTile(
                title: Text('الحساب مفعل'),
                subtitle: Text(_isActive ? 'يمكن للمستخدم تسجيل الدخول' : 'لا يمكن للمستخدم تسجيل الدخول'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                secondary: Icon(_isActive ? Icons.check_circle : Icons.cancel),
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.user == null ? 'إنشاء المستخدم' : 'تحديث المستخدم',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectValidationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validationEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _validationEndDate) {
      setState(() => _validationEndDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        final userController = Provider.of<UserController>(context, listen: false);
        
        String hashedPassword = widget.user?.password ?? _hashPassword(_passwordController.text);
        
        final user = UserModel(
          id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          username: _usernameController.text,
          password: hashedPassword,
          role: _role,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          isActive: _isActive,
          validationEndDate: _validationEndDate,
          createdAt: widget.user?.createdAt ?? DateTime.now(),
          createdBy: authController.currentUser!.id,
        );

        if (widget.user == null) {
          await userController.addUser(user);
        } else {
          await userController.updateUser(user);
        }
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ المستخدم بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ المستخدم: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
