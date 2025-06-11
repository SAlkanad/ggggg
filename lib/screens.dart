import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'models.dart';
import 'controllers.dart';
import 'services.dart';
import 'core.dart';

// screens/auth/login_screen.dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometricAvailability();
  }

  Future<void> _loadSavedCredentials() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final credentials = await authController.getSavedCredentials();

    if (credentials['username'] != null) {
      _usernameController.text = credentials['username']!;
    }
    if (credentials['password'] != null) {
      _passwordController.text = credentials['password']!;
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final isAvailable = await authController.checkBiometricAvailability();
    setState(() {
      _showBiometricButton = isAvailable && _usernameController.text.isNotEmpty;
    });
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
            if (authController.isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final user = authController.currentUser!;
                switch (user.role) {
                  case UserRole.admin:
                    Navigator.pushReplacementNamed(context, '/admin_dashboard');
                    break;
                  case UserRole.user:
                  case UserRole.agency:
                    Navigator.pushReplacementNamed(context, '/user_dashboard');
                    break;
                }
              });
            }

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
                      Icons.mosque,
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
                    onChanged: (value) => _checkBiometricAvailability(),
                  ),
                  SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock,
                    isPassword: true,
                    validator: ValidationUtils.validatePassword,
                  ),
                  SizedBox(height: 16),

                  CheckboxListTile(
                    title: Text('تذكرني'),
                    value: authController.rememberMe,
                    onChanged: (value) {
                      authController.rememberMe = value ?? false;
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 24),

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

                  if (_showBiometricButton) ...[
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: authController.isLoading ? null : _handleBiometricLogin,
                        icon: Icon(Icons.fingerprint),
                        label: Text('تسجيل الدخول ببصمة الإصبع'),
                      ),
                    ),
                  ],
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

  Future<void> _handleBiometricLogin() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.loginWithBiometric(_usernameController.text);

      if (success) {
        final user = authController.currentUser!;
        switch (user.role) {
          case UserRole.admin:
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
            break;
          case UserRole.user:
          case UserRole.agency:
            Navigator.pushReplacementNamed(context, '/user_dashboard');
            break;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في المصادقة ببصمة الإصبع')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المصادقة ببصمة الإصبع')),
      );
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

// screens/admin/admin_dashboard.dart
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المدير'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, notificationController, child) {
              return NotificationDropdown(
                notifications: notificationController.getUnreadNotifications(),
                onMarkAsRead: (id) => notificationController.markAsRead(id),
                onViewAll: () => Navigator.pushNamed(context, '/admin/notifications'),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _syncData(context),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthController>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              title: 'إدخال عميل',
              icon: Icons.person_add,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/admin/add_client'),
            ),
            _buildDashboardCard(
              title: 'إدارة العملاء',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/admin/manage_clients'),
            ),
            _buildDashboardCard(
              title: 'إدارة المستخدمين',
              icon: Icons.admin_panel_settings,
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/admin/manage_users'),
            ),
            _buildDashboardCard(
              title: 'الاشعارات',
              icon: Icons.notifications,
              color: Colors.red,
              onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
            ),
            _buildDashboardCard(
              title: 'الاعدادات',
              icon: Icons.settings,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/admin/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncData(BuildContext context) async {
    try {
      await StatusUpdateService.forceUpdateAllStatuses();

      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        final clientController = Provider.of<ClientController>(context, listen: false);
        final userController = Provider.of<UserController>(context, listen: false);
        final notificationController = Provider.of<NotificationController>(context, listen: false);

        await Future.wait([
          clientController.refreshClients(authController.currentUser!.id, isAdmin: true),
          userController.loadUsers(),
          notificationController.loadNotifications(authController.currentUser!.id, isAdmin: true),
        ]);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث البيانات: ${e.toString()}')),
      );
    }
  }
}

// screens/user/user_dashboard.dart
class UserDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المستخدم'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, notificationController, child) {
              return NotificationDropdown(
                notifications: notificationController.getUnreadNotifications(),
                onMarkAsRead: (id) => notificationController.markAsRead(id),
                onViewAll: () => Navigator.pushNamed(context, '/user/notifications'),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _syncData(context),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthController>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              title: 'إدخال العملاء',
              icon: Icons.person_add,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/user/add_client'),
            ),
            _buildDashboardCard(
              title: 'إدارة العملاء',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/user/manage_clients'),
            ),
            _buildDashboardCard(
              title: 'الاشعارات',
              icon: Icons.notifications,
              color: Colors.red,
              onTap: () => Navigator.pushNamed(context, '/user/notifications'),
            ),
            _buildDashboardCard(
              title: 'الاعدادات',
              icon: Icons.settings,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/user/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncData(BuildContext context) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        final clientController = Provider.of<ClientController>(context, listen: false);
        final notificationController = Provider.of<NotificationController>(context, listen: false);

        await Future.wait([
          clientController.refreshClients(authController.currentUser!.id),
          notificationController.loadNotifications(authController.currentUser!.id),
        ]);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث البيانات: ${e.toString()}')),
      );
    }
  }
}

// screens/admin/client_form_screen.dart
class ClientFormScreen extends StatefulWidget {
  final ClientModel? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _secondPhoneController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  PhoneCountry _phoneCountry = PhoneCountry.saudi;
  VisaType _visaType = VisaType.umrah;
  DateTime _entryDate = DateTime.now();
  List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _populateFields();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsController>(context, listen: false).loadAdminSettings();
    });
  }

  void _populateFields() {
    final client = widget.client!;
    _clientNameController.text = client.clientName;
    _clientPhoneController.text = client.clientPhone;
    _secondPhoneController.text = client.secondPhone ?? '';
    _phoneCountry = client.phoneCountry;
    _visaType = client.visaType;
    _agentNameController.text = client.agentName ?? '';
    _agentPhoneController.text = client.agentPhone ?? '';
    _entryDate = client.entryDate;
    _notesController.text = client.notes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'إضافة عميل جديد' : 'تعديل العميل'),
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
                controller: _clientNameController,
                label: 'اسم العميل *',
                icon: Icons.person,
                validator: ValidationUtils.validateRequired,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PhoneCountry>(
                      value: _phoneCountry,
                      decoration: InputDecoration(
                        labelText: 'الدولة',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: PhoneCountry.saudi,
                          child: Text('السعودية (+966)'),
                        ),
                        DropdownMenuItem(
                          value: PhoneCountry.yemen,
                          child: Text('اليمن (+967)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _phoneCountry = value!);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _clientPhoneController,
                      label: 'رقم العميل (اختياري)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) => ValidationUtils.validatePhone(value, _phoneCountry),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _secondPhoneController,
                label: 'رقم إضافي (اختياري)',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (value) => ValidationUtils.validatePhone(value, _phoneCountry),
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<VisaType>(
                value: _visaType,
                decoration: InputDecoration(
                  labelText: 'نوع التأشيرة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_membership),
                ),
                items: [
                  DropdownMenuItem(value: VisaType.visit, child: Text('زيارة')),
                  DropdownMenuItem(value: VisaType.work, child: Text('عمل')),
                  DropdownMenuItem(value: VisaType.umrah, child: Text('عمرة')),
                  DropdownMenuItem(value: VisaType.hajj, child: Text('حج')),
                ],
                onChanged: (value) => setState(() => _visaType = value!),
                validator: (value) => value == null ? 'اختر نوع التأشيرة' : null,
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _agentNameController,
                label: 'اسم الوكيل (اختياري)',
                icon: Icons.support_agent,
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _agentPhoneController,
                label: 'رقم الوكيل (اختياري)',
                icon: Icons.phone_callback,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              Card(
                child: ListTile(
                  title: Text('تاريخ الدخول'),
                  subtitle: Text(formatArabicDate(_entryDate)),
                  leading: Icon(Icons.calendar_today),
                  trailing: Icon(Icons.edit),
                  onTap: _selectEntryDate,
                ),
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات',
                icon: Icons.note,
                maxLines: 3,
              ),
              SizedBox(height: 16),

              _buildImageSection(),
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
                  widget.client == null ? 'حفظ العميل' : 'تحديث العميل',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.add_a_photo),
                label: Text('إضافة صور'),
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 16),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  width: 100,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectEntryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _entryDate) {
      setState(() => _entryDate = picked);
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        final clientController = Provider.of<ClientController>(context, listen: false);
        final settingsController = Provider.of<SettingsController>(context, listen: false);

        final settings = settingsController.adminSettings;
        final statusSettings = settings['clientStatusSettings'] ?? {};
        final greenDays = statusSettings['greenDays'] ?? 30;
        final yellowDays = statusSettings['yellowDays'] ?? 30;
        final redDays = statusSettings['redDays'] ?? 1;

        final client = ClientModel(
          id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          clientName: _clientNameController.text,
          clientPhone: _clientPhoneController.text,
          secondPhone: _secondPhoneController.text.isEmpty ? null : _secondPhoneController.text,
          phoneCountry: _phoneCountry,
          visaType: _visaType,
          agentName: _agentNameController.text.isEmpty ? null : _agentNameController.text,
          agentPhone: _agentPhoneController.text.isEmpty ? null : _agentPhoneController.text,
          entryDate: _entryDate,
          notes: _notesController.text,
          imageUrls: widget.client?.imageUrls ?? [],
          status: StatusCalculator.calculateStatus(
            _entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          ),
          daysRemaining: StatusCalculator.calculateDaysRemaining(_entryDate),
          createdBy: authController.currentUser!.id,
          createdAt: widget.client?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.client == null) {
          await clientController.addClient(client, _selectedImages);
        } else {
          await clientController.updateClient(client, _selectedImages);
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ العميل بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ العميل: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _secondPhoneController.dispose();
    _agentNameController.dispose();
    _agentPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// screens/admin/client_management_screen.dart
class ClientManagementScreen extends StatefulWidget {
  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<ClientController>(context, listen: false)
          .loadClients(authController.currentUser!.id, isAdmin: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العملاء'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/admin/add_client'),
            tooltip: 'إضافة عميل جديد',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
            tooltip: 'تصفية',
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _refreshClients(),
          ),
        ],
      ),
      body: Consumer<ClientController>(
        builder: (context, clientController, child) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'البحث بالاسم أو رقم الهاتف',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        clientController.clearSearch();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _performSearch(value),
                ),
              ),
              Expanded(
                child: clientController.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : clientController.clients.isEmpty
                    ? Center(child: Text('لا توجد عملاء مسجلون'))
                    : ListView.builder(
                  itemCount: clientController.clients.length,
                  itemBuilder: (context, index) {
                    final client = clientController.clients[index];
                    return ClientCard(
                      client: client,
                      onEdit: () => Navigator.pushNamed(
                        context,
                        '/admin/edit_client',
                        arguments: client,
                      ),
                      onDelete: () => _deleteClient(clientController, client.id),
                      onStatusChange: (status) => _updateStatus(clientController, client.id, status),
                      onViewImages: client.imageUrls.isNotEmpty
                          ? () => _viewImages(client.imageUrls)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مرشحات البحث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('قريباً سيتم إضافة مرشحات متقدمة'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    clientController.searchClients(query, authController.currentUser!.id, isAdmin: true);
  }

  void _refreshClients() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    clientController.refreshClients(authController.currentUser!.id, isAdmin: true);
  }

  void _deleteClient(ClientController controller, String clientId) async {
    try {
      await controller.deleteClient(clientId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف العميل بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حذف العميل: ${e.toString()}')),
      );
    }
  }

  void _updateStatus(ClientController controller, String clientId, ClientStatus status) async {
    try {
      await controller.updateClientStatus(clientId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة العميل')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الحالة: ${e.toString()}')),
      );
    }
  }

  void _viewImages(List<String> imageUrls) {
    Navigator.pushNamed(
      context,
      '/view_images',
      arguments: {
        'imageUrls': imageUrls,
        'initialIndex': 0,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// screens/user/user_client_form_screen.dart
class UserClientFormScreen extends StatelessWidget {
  final ClientModel? client;

  const UserClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClientFormScreen(client: client);
  }
}

// screens/user/user_client_management_screen.dart
class UserClientManagementScreen extends StatefulWidget {
  @override
  State<UserClientManagementScreen> createState() => _UserClientManagementScreenState();
}

class _UserClientManagementScreenState extends State<UserClientManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<ClientController>(context, listen: false)
          .loadClients(authController.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العملاء'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/user/add_client'),
            tooltip: 'إضافة عميل جديد',
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _refreshClients(),
          ),
        ],
      ),
      body: Consumer<ClientController>(
        builder: (context, clientController, child) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'البحث بالاسم أو رقم الهاتف',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        clientController.clearSearch();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _performSearch(value),
                ),
              ),
              Expanded(
                child: clientController.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : clientController.clients.isEmpty
                    ? Center(child: Text('لا توجد عملاء مسجلون'))
                    : ListView.builder(
                  itemCount: clientController.clients.length,
                  itemBuilder: (context, index) {
                    final client = clientController.clients[index];
                    return ClientCard(
                      client: client,
                      onEdit: () => Navigator.pushNamed(
                        context,
                        '/user/edit_client',
                        arguments: client,
                      ),
                      onDelete: () => _deleteClient(clientController, client.id),
                      onStatusChange: (status) => _updateStatus(clientController, client.id, status),
                      onViewImages: client.imageUrls.isNotEmpty
                          ? () => _viewImages(client.imageUrls)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _performSearch(String query) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    clientController.searchClients(query, authController.currentUser!.id);
  }

  void _refreshClients() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    clientController.refreshClients(authController.currentUser!.id);
  }

  void _deleteClient(ClientController controller, String clientId) async {
    try {
      await controller.deleteClient(clientId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف العميل بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حذف العميل: ${e.toString()}')),
      );
    }
  }

  void _updateStatus(ClientController controller, String clientId, ClientStatus status) async {
    try {
      await controller.updateClientStatus(clientId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة العميل')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الحالة: ${e.toString()}')),
      );
    }
  }

  void _viewImages(List<String> imageUrls) {
    Navigator.pushNamed(
      context,
      '/view_images',
      arguments: {
        'imageUrls': imageUrls,
        'initialIndex': 0,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// screens/admin/user_management_screen.dart
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
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => _refreshUsers(),
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

  void _refreshUsers() {
    Provider.of<UserController>(context, listen: false).loadUsers();
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

// screens/admin/user_form_screen.dart
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
                enabled: widget.user == null,
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

// screens/admin/user_clients_screen.dart
class UserClientsScreen extends StatefulWidget {
  final UserModel user;

  const UserClientsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserClientsScreen> createState() => _UserClientsScreenState();
}

class _UserClientsScreenState extends State<UserClientsScreen> {
  List<ClientModel> _clients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserClients();
  }

  Future<void> _loadUserClients() async {
    setState(() => _isLoading = true);

    try {
      final userController = Provider.of<UserController>(context, listen: false);
      _clients = await userController.getUserClients(widget.user.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب العملاء: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عملاء ${widget.user.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _loadUserClients,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _clients.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد عملاء لهذا المستخدم', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index];
          return ClientCard(
            client: client,
            onViewImages: client.imageUrls.isNotEmpty
                ? () => _viewImages(client.imageUrls)
                : null,
          );
        },
      ),
    );
  }

  void _viewImages(List<String> imageUrls) {
    Navigator.pushNamed(
      context,
      '/view_images',
      arguments: {
        'imageUrls': imageUrls,
        'initialIndex': 0,
      },
    );
  }
}

// screens/admin/admin_notifications_screen.dart
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
            icon: Icon(Icons.sync),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// screens/user/user_notifications_screen.dart
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
            icon: Icon(Icons.sync),
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

// screens/admin/admin_settings_screen.dart - Enhanced Version
class AdminSettingsScreen extends StatefulWidget {
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _greenDaysController = TextEditingController();
  final _yellowDaysController = TextEditingController();
  final _redDaysController = TextEditingController();

  final _clientTier1DaysController = TextEditingController();
  final _clientTier1FreqController = TextEditingController();
  final _clientTier1MessageController = TextEditingController();
  final _clientTier2DaysController = TextEditingController();
  final _clientTier2FreqController = TextEditingController();
  final _clientTier2MessageController = TextEditingController();
  final _clientTier3DaysController = TextEditingController();
  final _clientTier3FreqController = TextEditingController();
  final _clientTier3MessageController = TextEditingController();

  final _userTier1DaysController = TextEditingController();
  final _userTier1FreqController = TextEditingController();
  final _userTier1MessageController = TextEditingController();
  final _userTier2DaysController = TextEditingController();
  final _userTier2FreqController = TextEditingController();
  final _userTier2MessageController = TextEditingController();
  final _userTier3DaysController = TextEditingController();
  final _userTier3FreqController = TextEditingController();
  final _userTier3MessageController = TextEditingController();

  final _clientWhatsappController = TextEditingController();
  final _userWhatsappController = TextEditingController();

  bool _showOnlyMyClients = false;
  bool _showOnlyMyNotifications = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _checkBiometricStatus();
    });
  }

  Future<void> _loadSettings() async {
    final settingsController = Provider.of<SettingsController>(context, listen: false);
    await settingsController.loadAdminSettings();
    _populateFields();
  }

  Future<void> _checkBiometricStatus() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    setState(() {
      _biometricEnabled = authController.biometricEnabled;
    });
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).adminSettings;

    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? 30).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? 30).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? 1).toString();

    final clientSettings = settings['clientNotificationSettings'] ?? {};
    final clientTier1 = clientSettings['firstTier'] ?? {};
    final clientTier2 = clientSettings['secondTier'] ?? {};
    final clientTier3 = clientSettings['thirdTier'] ?? {};

    _clientTier1DaysController.text = (clientTier1['days'] ?? 10).toString();
    _clientTier1FreqController.text = (clientTier1['frequency'] ?? 2).toString();
    _clientTier1MessageController.text = clientTier1['message'] ?? 'تنبيه: تنتهي تأشيرة العميل {clientName} خلال 10 أيام';

    _clientTier2DaysController.text = (clientTier2['days'] ?? 5).toString();
    _clientTier2FreqController.text = (clientTier2['frequency'] ?? 4).toString();
    _clientTier2MessageController.text = clientTier2['message'] ?? 'تحذير: تنتهي تأشيرة العميل {clientName} خلال 5 أيام';

    _clientTier3DaysController.text = (clientTier3['days'] ?? 2).toString();
    _clientTier3FreqController.text = (clientTier3['frequency'] ?? 8).toString();
    _clientTier3MessageController.text = clientTier3['message'] ?? 'عاجل: تنتهي تأشيرة العميل {clientName} خلال يومين';

    final userSettings = settings['userNotificationSettings'] ?? {};
    final userTier1 = userSettings['firstTier'] ?? {};
    final userTier2 = userSettings['secondTier'] ?? {};
    final userTier3 = userSettings['thirdTier'] ?? {};

    _userTier1DaysController.text = (userTier1['days'] ?? 10).toString();
    _userTier1FreqController.text = (userTier1['frequency'] ?? 1).toString();
    _userTier1MessageController.text = userTier1['message'] ?? 'تنبيه: ينتهي حسابك خلال 10 أيام';

    _userTier2DaysController.text = (userTier2['days'] ?? 5).toString();
    _userTier2FreqController.text = (userTier2['frequency'] ?? 1).toString();
    _userTier2MessageController.text = userTier2['message'] ?? 'تحذير: ينتهي حسابك خلال 5 أيام';

    _userTier3DaysController.text = (userTier3['days'] ?? 2).toString();
    _userTier3FreqController.text = (userTier3['frequency'] ?? 1).toString();
    _userTier3MessageController.text = userTier3['message'] ?? 'عاجل: ينتهي حسابك خلال يومين';

    final whatsappMessages = settings['whatsappMessages'] ?? {};
    _clientWhatsappController.text = whatsappMessages['clientMessage'] ?? 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.';
    _userWhatsappController.text = whatsappMessages['userMessage'] ?? 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.';

    final adminFilters = settings['adminFilters'] ?? {};
    _showOnlyMyClients = adminFilters['showOnlyMyClients'] ?? false;
    _showOnlyMyNotifications = adminFilters['showOnlyMyNotifications'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات النظام'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Consumer<SettingsController>(
        builder: (context, settingsController, child) {
          if (settingsController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBiometricCard(),
                  SizedBox(height: 16),
                  _buildAdminFiltersCard(),
                  SizedBox(height: 16),
                  _buildStatusSettingsCard(),
                  SizedBox(height: 16),
                  _buildClientNotificationCard(),
                  SizedBox(height: 16),
                  _buildUserNotificationCard(),
                  SizedBox(height: 16),
                  _buildWhatsappMessagesCard(),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: Text('حفظ جميع الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBiometricCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text('المصادقة البيومترية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ],
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('تفعيل بصمة الإصبع', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('استخدم بصمة الإصبع لتسجيل الدخول السريع'),
                value: _biometricEnabled,
                onChanged: (value) async {
                  final authController = Provider.of<AuthController>(context, listen: false);
                  if (value) {
                    final isAvailable = await authController.checkBiometricAvailability();
                    if (isAvailable) {
                      await authController.enableBiometric();
                      setState(() => _biometricEnabled = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تفعيل المصادقة ببصمة الإصبع')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('بصمة الإصبع غير متاحة على هذا الجهاز')),
                      );
                    }
                  } else {
                    await authController.disableBiometric();
                    setState(() => _biometricEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إلغاء تفعيل المصادقة ببصمة الإصبع')),
                    );
                  }
                },
                secondary: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.security, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminFiltersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.purple, size: 28),
                  SizedBox(width: 12),
                  Text('مرشحات المدير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                ],
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('عرض عملائي فقط', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('إظهار العملاء المضافين من قبلي فقط'),
                value: _showOnlyMyClients,
                onChanged: (value) => setState(() => _showOnlyMyClients = value),
                secondary: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.people, color: Colors.purple),
                ),
              ),
              SwitchListTile(
                title: Text('عرض إشعاراتي فقط', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('إظهار الإشعارات المتعلقة بعملائي فقط'),
                value: _showOnlyMyNotifications,
                onChanged: (value) => setState(() => _showOnlyMyNotifications = value),
                secondary: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications, color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('إعدادات حالة العملاء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusField(_greenDaysController, 'أيام الحالة الخضراء', Colors.green, Icons.check_circle),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(_yellowDaysController, 'أيام الحالة الصفراء', Colors.orange, Icons.warning),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(_redDaysController, 'أيام الحالة الحمراء', Colors.red, Icons.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusField(TextEditingController controller, String label, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: color.withOpacity(0.5)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
            ),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('إعدادات الإشعارات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الأول', _tier1DaysController, _tier1FreqController, _tier1MessageController, Colors.green),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثاني', _tier2DaysController, _tier2FreqController, _tier2MessageController, Colors.orange),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثالث', _tier3DaysController, _tier3FreqController, _tier3MessageController, Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTier(String title, TextEditingController daysController, TextEditingController freqController, TextEditingController messageController, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الأيام',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.schedule, color: color),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: freqController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'التكرار يومياً',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.repeat, color: color),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'نص الرسالة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.message, color: color),
              ),
              validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsappMessageCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('رسالة الواتساب الافتراضية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _whatsappMessageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'نص الرسالة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.message, color: Colors.green),
                ),
                validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكن استخدام {clientName} في الرسالة',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        final settingsController = Provider.of<SettingsController>(context, listen: false);

        final settings = {
          'clientStatusSettings': {
            'greenDays': int.parse(_greenDaysController.text),
            'yellowDays': int.parse(_yellowDaysController.text),
            'redDays': int.parse(_redDaysController.text),
          },
          'notificationSettings': {
            'firstTier': {
              'days': int.parse(_tier1DaysController.text),
              'frequency': int.parse(_tier1FreqController.text),
              'message': _tier1MessageController.text,
            },
            'secondTier': {
              'days': int.parse(_tier2DaysController.text),
              'frequency': int.parse(_tier2FreqController.text),
              'message': _tier2MessageController.text,
            },
            'thirdTier': {
              'days': int.parse(_tier3DaysController.text),
              'frequency': int.parse(_tier3FreqController.text),
              'message': _tier3MessageController.text,
            },
          },
          'whatsappMessage': _whatsappMessageController.text,
          'profile': {
            'notifications': _notificationsEnabled,
            'whatsapp': _whatsappEnabled,
            'autoSchedule': _autoScheduleEnabled,
            'biometric': _biometricEnabled,
          },
        };

        await settingsController.updateUserSettings(authController.currentUser!.id, settings);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم حفظ الإعدادات بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('خطأ في حفظ الإعدادات: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _greenDaysController.dispose();
    _yellowDaysController.dispose();
    _redDaysController.dispose();
    _tier1DaysController.dispose();
    _tier1FreqController.dispose();
    _tier1MessageController.dispose();
    _tier2DaysController.dispose();
    _tier2FreqController.dispose();
    _tier2MessageController.dispose();
    _tier3DaysController.dispose();
    _tier3FreqController.dispose();
    _tier3MessageController.dispose();
    _whatsappMessageController.dispose();
    super.dispose();
  }
}

// Additional Widget Implementations

// Enhanced Client Card with improved functionality
class EnhancedClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(ClientStatus)? onStatusChange;
  final VoidCallback? onViewImages;
  final String? createdByName;
  final bool showActions;

  const EnhancedClientCard({
    Key? key,
    required this.client,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.onViewImages,
    this.createdByName,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getStatusGradientColor().withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.clientName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            StatusCard(
                              status: client.status,
                              daysRemaining: client.daysRemaining,
                            ),
                          ],
                        ),
                        if (createdByName != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: 12, color: Colors.blue.shade700),
                                SizedBox(width: 4),
                                Text(
                                  'بواسطة: $createdByName',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Client Information Grid
              _buildInfoGrid(),

              if (client.imageUrls.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildImageSection(),
              ],

              if (showActions) ...[
                SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        if (client.clientPhone.isNotEmpty)
          _buildInfoRow(Icons.phone, 'الهاتف', client.clientPhone),

        if (client.secondPhone != null && client.secondPhone!.isNotEmpty)
          _buildInfoRow(Icons.phone_android, 'هاتف إضافي', client.secondPhone!),

        _buildInfoRow(Icons.card_membership, 'نوع التأشيرة', _getVisaTypeText(client.visaType)),

        _buildInfoRow(Icons.calendar_today, 'تاريخ الدخول', formatArabicDate(client.entryDate)),

        if (client.agentName != null && client.agentName!.isNotEmpty)
          _buildInfoRow(Icons.support_agent, 'الوكيل', client.agentName!),

        if (client.notes.isNotEmpty)
          _buildInfoRow(Icons.note, 'ملاحظات', client.notes, maxLines: 2),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade600),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.image, size: 20, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            '${client.imageUrls.length} صورة مرفقة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          if (onViewImages != null)
            TextButton.icon(
              onPressed: onViewImages,
              icon: Icon(Icons.visibility, size: 16),
              label: Text('عرض'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                minimumSize: Size(0, 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!client.hasExited && client.clientPhone.isNotEmpty) ...[
            _buildActionButton(
              icon: Icons.message,
              label: 'واتساب',
              color: Colors.green,
              onPressed: () => _sendWhatsApp(context),
            ),
            _buildActionButton(
              icon: Icons.call,
              label: 'اتصال',
              color: Colors.blue,
              onPressed: () => _makeCall(client.clientPhone),
            ),
          ],

          if (onEdit != null)
            _buildActionButton(
              icon: Icons.edit,
              label: 'تعديل',
              color: Colors.orange,
              onPressed: onEdit!,
            ),

          if (onStatusChange != null && !client.hasExited)
            _buildActionButton(
              icon: Icons.exit_to_app,
              label: 'خرج',
              color: Colors.grey,
              onPressed: () => onStatusChange!(ClientStatus.white),
            ),

          if (onDelete != null)
            _buildActionButton(
              icon: Icons.delete,
              label: 'حذف',
              color: Colors.red,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusGradientColor() {
    switch (client.status) {
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
      // Handle silently
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من حذف العميل؟'),
            SizedBox(height: 8),
            Text(
              client.clientName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Enhanced Notification Card with better UI
class EnhancedNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onDismiss;

  const EnhancedNotificationCard({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
    this.onWhatsApp,
    this.onCall,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        elevation: notification.isRead ? 1 : 4,
        color: notification.isRead ? Colors.grey.shade50 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getPriorityColor().withOpacity(0.3),
            width: notification.isRead ? 0.5 : 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      color: _getPriorityColor(),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: notification.isRead ? Colors.grey.shade600 : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getPriorityText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.access_time, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              formatTimeAgo(notification.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12),

              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: notification.isRead ? Colors.grey.shade600 : Colors.black87,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 16),

              Row(
                children: [
                  if (onWhatsApp != null)
                    _buildActionButton(
                      icon: Icons.message,
                      label: 'واتساب',
                      color: Colors.green,
                      onPressed: onWhatsApp!,
                    ),

                  if (onCall != null) ...[
                    if (onWhatsApp != null) SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.call,
                      label: 'اتصال',
                      color: Colors.blue,
                      onPressed: onCall!,
                    ),
                  ],

                  Spacer(),

                  if (!notification.isRead && onMarkAsRead != null)
                    _buildActionButton(
                      icon: Icons.mark_email_read,
                      label: 'مقروء',
                      color: Colors.orange,
                      onPressed: onMarkAsRead!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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

  String _getPriorityText() {
    switch (notification.priority) {
      case NotificationPriority.high:
        return 'عاجل';
      case NotificationPriority.medium:
        return 'متوسط';
      case NotificationPriority.low:
        return 'عادي';
    }
  }
}

// Dashboard Statistics Widget
class DashboardStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const DashboardStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Spacer(),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
              SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}