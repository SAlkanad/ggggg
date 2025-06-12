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
import 'settings_screens.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
                    onChanged: (value) => authController.checkBiometricAvailability(),
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

                  if (authController.biometricAvailable && _usernameController.text.isNotEmpty) ...[
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

// Fixed section from screens.dart - around line 800-900
// The issue was that the _ClientFormScreenState class was not properly closed
// and the dispose method was orphaned outside the class

class ClientFormScreen extends BaseFormScreen {
  final ClientModel? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends BaseFormScreenState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientPhoneController;
  late final TextEditingController _secondPhoneController;
  late final TextEditingController _agentNameController;
  late final TextEditingController _agentPhoneController;
  late final TextEditingController _notesController;

  PhoneCountry _phoneCountry = PhoneCountry.saudi;
  VisaType _visaType = VisaType.umrah;
  DateTime _entryDate = DateTime.now();
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();

    _clientNameController = TextEditingController();
    _clientPhoneController = TextEditingController();
    _secondPhoneController = TextEditingController();
    _agentNameController = TextEditingController();
    _agentPhoneController = TextEditingController();
    _notesController = TextEditingController();

    registerController(_clientNameController);
    registerController(_clientPhoneController);
    registerController(_secondPhoneController);
    registerController(_agentNameController);
    registerController(_agentPhoneController);
    registerController(_notesController);

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
            onPressed: isLoading ? null : _handleSave,
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

              DropdownButtonFormField<PhoneCountry>(
                value: _phoneCountry,
                decoration: InputDecoration(
                  labelText: 'الدولة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
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
                validator: (value) => value == null ? 'اختر الدولة' : null,
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _clientPhoneController,
                label: 'رقم العميل الأساسي *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => ValidationUtils.validateClientPhone(value, _phoneCountry),
              ),
              SizedBox(height: 16),

              CustomTextField(
                controller: _secondPhoneController,
                label: 'رقم إضافي (اختياري)',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (value) => ValidationUtils.validateSecondPhone(value, _phoneCountry),
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
                onPressed: isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
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
      setLoading(true);

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
          username: _clientNameController.text, // Add username field
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

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ العميل بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حفظ العميل: ${e.toString()}')),
          );
        }
      } finally {
        setLoading(false);
      }
    }
  }

  // FIXED: This dispose method should be inside the _ClientFormScreenState class
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
} // Properly close the _ClientFormScreenState class

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
                    final createdByName = clientController.getUserNameById(client.createdBy);
                    return ClientCard(
                      client: client,
                      createdByName: createdByName,
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
    final clientController = Provider.of<ClientController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        currentFilter: clientController.currentFilter,
        users: clientController.users,
        onApplyFilter: (filter) {
          final authController = Provider.of<AuthController>(context, listen: false);
          clientController.applyFilter(filter, authController.currentUser!.id, isAdmin: true);
        },
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

class UserClientFormScreen extends StatelessWidget {
  final ClientModel? client;

  const UserClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClientFormScreen(client: client);
  }
}

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
      final user = await DatabaseService.getUserById(notification.targetUserId);
      if (user != null) {
        await Provider.of<NotificationController>(context, listen: false)
            .sendWhatsAppToUser(user, notification.message);
      }
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