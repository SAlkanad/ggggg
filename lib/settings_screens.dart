import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'controllers.dart';
import 'services.dart';
import 'core.dart';
import 'error_handler.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Status Settings Controllers
  final _greenDaysController = TextEditingController();
  final _yellowDaysController = TextEditingController();
  final _redDaysController = TextEditingController();

  // Client Notification Controllers
  final _clientTier1DaysController = TextEditingController();
  final _clientTier1FreqController = TextEditingController();
  final _clientTier1MessageController = TextEditingController();
  final _clientTier2DaysController = TextEditingController();
  final _clientTier2FreqController = TextEditingController();
  final _clientTier2MessageController = TextEditingController();
  final _clientTier3DaysController = TextEditingController();
  final _clientTier3FreqController = TextEditingController();
  final _clientTier3MessageController = TextEditingController();

  // User Notification Controllers
  final _userTier1DaysController = TextEditingController();
  final _userTier1FreqController = TextEditingController();
  final _userTier1MessageController = TextEditingController();
  final _userTier2DaysController = TextEditingController();
  final _userTier2FreqController = TextEditingController();
  final _userTier2MessageController = TextEditingController();
  final _userTier3DaysController = TextEditingController();
  final _userTier3FreqController = TextEditingController();
  final _userTier3MessageController = TextEditingController();

  // WhatsApp Message Controllers
  final _clientWhatsappController = TextEditingController();
  final _userWhatsappController = TextEditingController();

  // Settings Variables
  bool _showOnlyMyClients = false;
  bool _showOnlyMyNotifications = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _checkBiometricStatus();
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settingsController = Provider.of<SettingsController>(context, listen: false);
      await settingsController.loadAdminSettings();
      _populateFields();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final isEnabled = authController.biometricEnabled;
      if (mounted) {
        setState(() => _biometricEnabled = isEnabled);
      }
    } catch (e) {
      // Biometric status check failed, continue with default value
    }
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).adminSettings;

    // Status Settings
    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? AppConstants.defaultGreenDays).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? AppConstants.defaultYellowDays).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? AppConstants.defaultRedDays).toString();

    // Client Notification Settings
    final clientSettings = settings['clientNotificationSettings'] ?? {};
    final clientTier1 = clientSettings['firstTier'] ?? {};
    final clientTier2 = clientSettings['secondTier'] ?? {};
    final clientTier3 = clientSettings['thirdTier'] ?? {};

    _clientTier1DaysController.text = (clientTier1['days'] ?? AppConstants.firstTierDays).toString();
    _clientTier1FreqController.text = (clientTier1['frequency'] ?? AppConstants.firstTierFrequency).toString();
    _clientTier1MessageController.text = clientTier1['message'] ?? MessageTemplates.clientMessages['tier1']!;

    _clientTier2DaysController.text = (clientTier2['days'] ?? AppConstants.secondTierDays).toString();
    _clientTier2FreqController.text = (clientTier2['frequency'] ?? AppConstants.secondTierFrequency).toString();
    _clientTier2MessageController.text = clientTier2['message'] ?? MessageTemplates.clientMessages['tier2']!;

    _clientTier3DaysController.text = (clientTier3['days'] ?? AppConstants.thirdTierDays).toString();
    _clientTier3FreqController.text = (clientTier3['frequency'] ?? AppConstants.thirdTierFrequency).toString();
    _clientTier3MessageController.text = clientTier3['message'] ?? MessageTemplates.clientMessages['tier3']!;

    // User Notification Settings
    final userSettings = settings['userNotificationSettings'] ?? {};
    final userTier1 = userSettings['firstTier'] ?? {};
    final userTier2 = userSettings['secondTier'] ?? {};
    final userTier3 = userSettings['thirdTier'] ?? {};

    _userTier1DaysController.text = (userTier1['days'] ?? AppConstants.firstTierDays).toString();
    _userTier1FreqController.text = (userTier1['frequency'] ?? AppConstants.userFirstTierFreq).toString();
    _userTier1MessageController.text = userTier1['message'] ?? MessageTemplates.userMessages['tier1']!;

    _userTier2DaysController.text = (userTier2['days'] ?? AppConstants.secondTierDays).toString();
    _userTier2FreqController.text = (userTier2['frequency'] ?? AppConstants.userSecondTierFreq).toString();
    _userTier2MessageController.text = userTier2['message'] ?? MessageTemplates.userMessages['tier2']!;

    _userTier3DaysController.text = (userTier3['days'] ?? AppConstants.thirdTierDays).toString();
    _userTier3FreqController.text = (userTier3['frequency'] ?? AppConstants.userThirdTierFreq).toString();
    _userTier3MessageController.text = userTier3['message'] ?? MessageTemplates.userMessages['tier3']!;

    // WhatsApp Messages
    final whatsappMessages = settings['whatsappMessages'] ?? {};
    _clientWhatsappController.text = whatsappMessages['clientMessage'] ?? AppConstants.defaultClientMessage;
    _userWhatsappController.text = whatsappMessages['userMessage'] ?? AppConstants.defaultUserMessage;

    // Admin Filters
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
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'حفظ الإعدادات',
          ),
        ],
      ),
      body: Consumer<SettingsController>(
        builder: (context, settingsController, child) {
          if (_isLoading || settingsController.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الإعدادات...'),
                ],
              ),
            );
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
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('جاري الحفظ...'),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text('حفظ جميع الإعدادات',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fingerprint, color: Colors.blue, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'المصادقة البيومترية',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: SwitchListTile(
                  title: Text('تفعيل بصمة الإصبع', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('استخدم بصمة الإصبع لتسجيل الدخول السريع'),
                  value: _biometricEnabled,
                  onChanged: _handleBiometricToggle,
                  secondary: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.security, color: Colors.blue),
                  ),
                  activeColor: Colors.blue,
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.admin_panel_settings, color: Colors.purple, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'مرشحات المدير',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildFilterSwitchTile(
                'عرض عملائي فقط',
                'إظهار العملاء المضافين من قبلي فقط',
                Icons.people,
                Colors.purple,
                _showOnlyMyClients,
                    (value) => setState(() => _showOnlyMyClients = value),
              ),
              SizedBox(height: 8),
              _buildFilterSwitchTile(
                'عرض إشعاراتي فقط',
                'إظهار الإشعارات المتعلقة بعملائي فقط',
                Icons.notifications,
                Colors.purple,
                _showOnlyMyNotifications,
                    (value) => setState(() => _showOnlyMyNotifications = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSwitchTile(String title, String subtitle, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        activeColor: color,
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timeline, color: Colors.green, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات حالة العملاء',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusField(
                        _greenDaysController,
                        'أيام الحالة الخضراء',
                        Colors.green,
                        Icons.check_circle
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(
                        _yellowDaysController,
                        'أيام الحالة الصفراء',
                        Colors.orange,
                        Icons.warning
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(
                        _redDaysController,
                        'أيام الحالة الحمراء',
                        Colors.red,
                        Icons.error
                    ),
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
              validator: (value) {
                if (value == null || value.isEmpty) return 'مطلوب';
                final num = int.tryParse(value);
                if (num == null || num < 1) return 'يجب أن يكون رقم موجب';
                return null;
              },
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientNotificationCard() {
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_pin, color: Colors.blue, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات إشعارات العملاء',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الأول',
                  _clientTier1DaysController,
                  _clientTier1FreqController,
                  _clientTier1MessageController,
                  Colors.green
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثاني',
                  _clientTier2DaysController,
                  _clientTier2FreqController,
                  _clientTier2MessageController,
                  Colors.orange
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثالث',
                  _clientTier3DaysController,
                  _clientTier3FreqController,
                  _clientTier3MessageController,
                  Colors.red
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserNotificationCard() {
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group, color: Colors.orange, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات إشعارات المستخدمين',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الأول',
                  _userTier1DaysController,
                  _userTier1FreqController,
                  _userTier1MessageController,
                  Colors.green
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثاني',
                  _userTier2DaysController,
                  _userTier2FreqController,
                  _userTier2MessageController,
                  Colors.orange
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثالث',
                  _userTier3DaysController,
                  _userTier3FreqController,
                  _userTier3MessageController,
                  Colors.red
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTier(
      String title,
      TextEditingController daysController,
      TextEditingController freqController,
      TextEditingController messageController,
      Color color
      ) {
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
            Row(
              children: [
                Icon(Icons.notifications_active, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16
                  ),
                ),
              ],
            ),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      final num = int.tryParse(value);
                      if (num == null || num < 1) return 'رقم موجب';
                      return null;
                    },
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      final num = int.tryParse(value);
                      if (num == null || num < 1) return 'رقم موجب';
                      return null;
                    },
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (value) => ValidationUtils.validateRequired(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsappMessagesCard() {
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chat, color: Colors.green, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'رسائل الواتساب الافتراضية',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _clientWhatsappController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'رسالة العملاء',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person, color: Colors.green),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) => ValidationUtils.validateRequired(value),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _userWhatsappController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'رسالة المستخدمين',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.group, color: Colors.green),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) => ValidationUtils.validateRequired(value),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكن استخدام {clientName} أو {userName} في الرسائل',
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

  void _handleBiometricToggle(bool value) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);

      if (value) {
        final isAvailable = await authController.checkBiometricAvailability();
        if (isAvailable) {
          await authController.enableBiometric();
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم تفعيل المصادقة ببصمة الإصبع'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('بصمة الإصبع غير متاحة على هذا الجهاز'),
                ],
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await authController.disableBiometric();
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('تم إلغاء تفعيل المصادقة ببصمة الإصبع'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('يرجى تصحيح الأخطاء في النموذج'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final settingsController = Provider.of<SettingsController>(context, listen: false);

      final settings = {
        'clientStatusSettings': {
          'greenDays': int.parse(_greenDaysController.text),
          'yellowDays': int.parse(_yellowDaysController.text),
          'redDays': int.parse(_redDaysController.text),
        },
        'clientNotificationSettings': {
          'firstTier': {
            'days': int.parse(_clientTier1DaysController.text),
            'frequency': int.parse(_clientTier1FreqController.text),
            'message': _clientTier1MessageController.text,
          },
          'secondTier': {
            'days': int.parse(_clientTier2DaysController.text),
            'frequency': int.parse(_clientTier2FreqController.text),
            'message': _clientTier2MessageController.text,
          },
          'thirdTier': {
            'days': int.parse(_clientTier3DaysController.text),
            'frequency': int.parse(_clientTier3FreqController.text),
            'message': _clientTier3MessageController.text,
          },
        },
        'userNotificationSettings': {
          'firstTier': {
            'days': int.parse(_userTier1DaysController.text),
            'frequency': int.parse(_userTier1FreqController.text),
            'message': _userTier1MessageController.text,
          },
          'secondTier': {
            'days': int.parse(_userTier2DaysController.text),
            'frequency': int.parse(_userTier2FreqController.text),
            'message': _userTier2MessageController.text,
          },
          'thirdTier': {
            'days': int.parse(_userTier3DaysController.text),
            'frequency': int.parse(_userTier3FreqController.text),
            'message': _userTier3MessageController.text,
          },
        },
        'whatsappMessages': {
          'clientMessage': _clientWhatsappController.text,
          'userMessage': _userWhatsappController.text,
        },
        'adminFilters': {
          'showOnlyMyClients': _showOnlyMyClients,
          'showOnlyMyNotifications': _showOnlyMyNotifications,
        },
      };

      await settingsController.updateAdminSettings(settings);

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
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _greenDaysController.dispose();
    _yellowDaysController.dispose();
    _redDaysController.dispose();

    _clientTier1DaysController.dispose();
    _clientTier1FreqController.dispose();
    _clientTier1MessageController.dispose();
    _clientTier2DaysController.dispose();
    _clientTier2FreqController.dispose();
    _clientTier2MessageController.dispose();
    _clientTier3DaysController.dispose();
    _clientTier3FreqController.dispose();
    _clientTier3MessageController.dispose();

    _userTier1DaysController.dispose();
    _userTier1FreqController.dispose();
    _userTier1MessageController.dispose();
    _userTier2DaysController.dispose();
    _userTier2FreqController.dispose();
    _userTier2MessageController.dispose();
    _userTier3DaysController.dispose();
    _userTier3FreqController.dispose();
    _userTier3MessageController.dispose();

    _clientWhatsappController.dispose();
    _userWhatsappController.dispose();

    super.dispose();
  }
}

// User Settings Screen
class UserSettingsScreen extends StatefulWidget {
  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Status Settings Controllers
  final _greenDaysController = TextEditingController();
  final _yellowDaysController = TextEditingController();
  final _redDaysController = TextEditingController();

  // Notification Controllers
  final _tier1DaysController = TextEditingController();
  final _tier1FreqController = TextEditingController();
  final _tier1MessageController = TextEditingController();
  final _tier2DaysController = TextEditingController();
  final _tier2FreqController = TextEditingController();
  final _tier2MessageController = TextEditingController();
  final _tier3DaysController = TextEditingController();
  final _tier3FreqController = TextEditingController();
  final _tier3MessageController = TextEditingController();

  // WhatsApp Message Controller
  final _whatsappMessageController = TextEditingController();

  // Settings Variables
  bool _notificationsEnabled = true;
  bool _whatsappEnabled = true;
  bool _autoScheduleEnabled = true;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _checkBiometricStatus();
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final settingsController = Provider.of<SettingsController>(context, listen: false);

      if (authController.currentUser != null) {
        await settingsController.loadUserSettings(authController.currentUser!.id);
        _populateFields();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final isEnabled = authController.biometricEnabled;
      if (mounted) {
        setState(() => _biometricEnabled = isEnabled);
      }
    } catch (e) {
      // Biometric status check failed, continue with default value
    }
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).userSettings;

    // Status Settings
    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? AppConstants.defaultGreenDays).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? AppConstants.defaultYellowDays).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? AppConstants.defaultRedDays).toString();

    // Notification Settings
    final notificationSettings = settings['notificationSettings'] ?? {};
    final tier1 = notificationSettings['firstTier'] ?? {};
    final tier2 = notificationSettings['secondTier'] ?? {};
    final tier3 = notificationSettings['thirdTier'] ?? {};

    _tier1DaysController.text = (tier1['days'] ?? AppConstants.firstTierDays).toString();
    _tier1FreqController.text = (tier1['frequency'] ?? AppConstants.firstTierFrequency).toString();
    _tier1MessageController.text = tier1['message'] ?? MessageTemplates.clientMessages['tier1']!;

    _tier2DaysController.text = (tier2['days'] ?? AppConstants.secondTierDays).toString();
    _tier2FreqController.text = (tier2['frequency'] ?? AppConstants.secondTierFrequency).toString();
    _tier2MessageController.text = tier2['message'] ?? MessageTemplates.clientMessages['tier2']!;

    _tier3DaysController.text = (tier3['days'] ?? AppConstants.thirdTierDays).toString();
    _tier3FreqController.text = (tier3['frequency'] ?? AppConstants.thirdTierFrequency).toString();
    _tier3MessageController.text = tier3['message'] ?? MessageTemplates.clientMessages['tier3']!;

    // WhatsApp Message
    _whatsappMessageController.text = settings['whatsappMessage'] ?? AppConstants.defaultClientMessage;

    // Profile Settings
    final profile = settings['profile'] ?? {};
    _notificationsEnabled = profile['notifications'] ?? true;
    _whatsappEnabled = profile['whatsapp'] ?? true;
    _autoScheduleEnabled = profile['autoSchedule'] ?? true;
    _biometricEnabled = profile['biometric'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'حفظ الإعدادات',
          ),
        ],
      ),
      body: Consumer<SettingsController>(
        builder: (context, settingsController, child) {
          if (_isLoading || settingsController.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الإعدادات...'),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileSettingsCard(),
                  SizedBox(height: 16),
                  _buildBiometricCard(),
                  SizedBox(height: 16),
                  _buildStatusSettingsCard(),
                  SizedBox(height: 16),
                  _buildNotificationCard(),
                  SizedBox(height: 16),
                  _buildWhatsappMessageCard(),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('جاري الحفظ...'),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text('حفظ الإعدادات',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSettingsCard() {
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person, color: Colors.blue, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات الملف الشخصي',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildSwitchTile(
                'تفعيل الإشعارات',
                'استقبال إشعارات انتهاء التأشيرات',
                Icons.notifications,
                Colors.orange,
                _notificationsEnabled,
                    (value) => setState(() => _notificationsEnabled = value),
              ),
              SizedBox(height: 8),
              _buildSwitchTile(
                'تفعيل الواتساب',
                'إمكانية إرسال رسائل واتساب',
                Icons.message,
                Colors.green,
                _whatsappEnabled,
                    (value) => setState(() => _whatsappEnabled = value),
              ),
              SizedBox(height: 8),
              _buildSwitchTile(
                'الجدولة التلقائية',
                'جدولة الإشعارات تلقائياً',
                Icons.schedule,
                Colors.purple,
                _autoScheduleEnabled,
                    (value) => setState(() => _autoScheduleEnabled = value),
              ),
            ],
          ),
        ),
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
            colors: [Colors.indigo.shade50, Colors.white],
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fingerprint, color: Colors.indigo, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'المصادقة البيومترية',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildSwitchTile(
                'تفعيل بصمة الإصبع',
                'استخدم بصمة الإصبع لتسجيل الدخول السريع',
                Icons.security,
                Colors.indigo,
                _biometricEnabled,
                _handleBiometricToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        activeColor: color,
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timeline, color: Colors.green, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات حالة العملاء',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusField(
                        _greenDaysController,
                        'أيام الحالة الخضراء',
                        Colors.green,
                        Icons.check_circle
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(
                        _yellowDaysController,
                        'أيام الحالة الصفراء',
                        Colors.orange,
                        Icons.warning
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusField(
                        _redDaysController,
                        'أيام الحالة الحمراء',
                        Colors.red,
                        Icons.error
                    ),
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
              validator: (value) {
                if (value == null || value.isEmpty) return 'مطلوب';
                final num = int.tryParse(value);
                if (num == null || num < 1) return 'يجب أن يكون رقم موجب';
                return null;
              },
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_active, color: Colors.orange, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'إعدادات الإشعارات',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الأول',
                  _tier1DaysController,
                  _tier1FreqController,
                  _tier1MessageController,
                  Colors.green
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثاني',
                  _tier2DaysController,
                  _tier2FreqController,
                  _tier2MessageController,
                  Colors.orange
              ),
              SizedBox(height: 16),
              _buildNotificationTier(
                  'المستوى الثالث',
                  _tier3DaysController,
                  _tier3FreqController,
                  _tier3MessageController,
                  Colors.red
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTier(
      String title,
      TextEditingController daysController,
      TextEditingController freqController,
      TextEditingController messageController,
      Color color
      ) {
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
            Row(
              children: [
                Icon(Icons.notifications_active, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16
                  ),
                ),
              ],
            ),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      final num = int.tryParse(value);
                      if (num == null || num < 1) return 'رقم موجب';
                      return null;
                    },
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      final num = int.tryParse(value);
                      if (num == null || num < 1) return 'رقم موجب';
                      return null;
                    },
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (value) => ValidationUtils.validateRequired(value),
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chat, color: Colors.green, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'رسالة الواتساب الافتراضية',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800
                    ),
                  ),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) => ValidationUtils.validateRequired(value),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
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

  void _handleBiometricToggle(bool value) async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);

      if (value) {
        final isAvailable = await authController.checkBiometricAvailability();
        if (isAvailable) {
          await authController.enableBiometric();
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم تفعيل المصادقة ببصمة الإصبع'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('بصمة الإصبع غير متاحة على هذا الجهاز'),
                ],
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await authController.disableBiometric();
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('تم إلغاء تفعيل المصادقة ببصمة الإصبع'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('يرجى تصحيح الأخطاء في النموذج'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final settingsController = Provider.of<SettingsController>(context, listen: false);

      if (authController.currentUser == null) {
        throw Exception('المستخدم غير متصل');
      }

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
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
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