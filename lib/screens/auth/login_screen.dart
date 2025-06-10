import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validation_utils.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final credentials = await authController.getSavedCredentials();
    
    if (credentials['rememberMe'] == 'true') {
      setState(() {
        _usernameController.text = credentials['username'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            return Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  CustomTextField(
                    controller: _usernameController,
                    label: 'اسم المستخدم',
                    icon: Icons.person,
                    validator: ValidationUtils.validateUsername,
                  ),
                  SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock,
                    isPassword: true,
                    validator: ValidationUtils.validatePassword,
                  ),
                  SizedBox(height: 8),

                  CheckboxListTile(
                    title: Text('تذكرني'),
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authController.isLoading ? null : _handleLogin,
                      child: authController.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('دخول', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        final success = await authController.login(
          _usernameController.text,
          _passwordController.text,
          rememberMe: _rememberMe,
        );
        
        if (success) {
          final user = authController.currentUser!;
          
          if (user.isFrozen) {
            _showFreezeDialog(user.freezeReason ?? 'تم تجميد الحساب');
            return;
          }
          
          switch (user.role) {
            case UserRole.admin:
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
              break;
            case UserRole.user:
            case UserRole.agency:
              Navigator.pushReplacementNamed(context, '/user_dashboard');
              break;
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showFreezeDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حساب مجمد'),
        content: Text('تم تجميد حسابك: $reason'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}