import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/widgets/notification_dropdown.dart';
import '../../services/status_update_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    final userController = Provider.of<UserController>(context, listen: false);
    final notificationController = Provider.of<NotificationController>(context, listen: false);

    try {
      await Future.wait([
        clientController.loadClients(authController.currentUser!.id, isAdmin: true),
        userController.loadUsers(),
        notificationController.loadNotifications(authController.currentUser!.id, isAdmin: true),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      // Force update all client statuses
      await StatusUpdateService.forceUpdateAllStatuses();
      
      // Reload all data
      await _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث البيانات: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المدير'),
        actions: [
          NotificationDropdown(),
          IconButton(
            icon: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncData,
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
      body: RefreshIndicator(
        onRefresh: _syncData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatsCards(),
              SizedBox(height: 24),
              _buildDashboardGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer2<ClientController, UserController>(
      builder: (context, clientController, userController, child) {
        return Container(
          height: 120,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'العملاء',
                  clientController.getClientsCount().toString(),
                  Icons.people,
                  Colors.blue,
                  subtitle: 'نشط: ${clientController.getActiveClientsCount()}',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'المستخدمين',
                  userController.users.length.toString(),
                  Icons.admin_panel_settings,
                  Colors.green,
                  subtitle: 'مفعل: ${userController.users.where((u) => u.isActive && !u.isFrozen).length}',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'تحذيرات',
                  clientController.getRedClients().length.toString(),
                  Icons.warning,
                  Colors.red,
                  subtitle: 'عاجل',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Consumer<NotificationController>(
                  builder: (context, notificationController, child) {
                    return _buildStatCard(
                      'إشعارات',
                      notificationController.getUnreadCount().toString(),
                      Icons.notifications,
                      Colors.orange,
                      subtitle: 'غير مقروءة',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildDashboardCard(
          title: 'إدخال عميل',
          icon: Icons.person_add,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/admin/add_client').then((_) => _loadDashboardData()),
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
        _buildDashboardCard(
          title: 'تحديث البيانات',
          icon: Icons.refresh,
          color: Colors.teal,
          onTap: _syncData,
          loading: _isSyncing,
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: loading ? null : onTap,
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
              if (loading)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
              else
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
}