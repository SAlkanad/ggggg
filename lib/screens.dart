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
              if (clientController.currentFilter.hasActiveFilters)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('تم تطبيق مرشحات', style: TextStyle(color: Colors.blue)),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          clientController.clearFilter();
                          _refreshClients();
                        },
                        child: Text('مسح المرشحات'),
                      ),
                    ],
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

class UserClientFormScreen extends StatelessWidget {
  final ClientModel? client;

  const UserClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClientFormScreen(client: client);
  }
}