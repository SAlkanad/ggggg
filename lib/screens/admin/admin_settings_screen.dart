import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../controllers/settings_controller.dart';
import '../../services/biometric_auth_service.dart';
import '../../core/widgets/custom_text_field.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
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

  // Biometric Settings
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _checkBiometricAvailability();
    });
  }

  Future<void> _loadSettings() async {
    final settingsController = Provider.of<SettingsController>(context, listen: false);
    await settingsController.loadAdminSettings();
    _populateFields();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final biometrics = await BiometricService.getAvailableBiometrics();
    
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _availableBiometrics = biometrics;
    });
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).adminSettings;
    
    // Status Settings
    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? 30).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? 30).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? 1).toString();
    
    // Client Notification Settings
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
    
    // User Notification Settings
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
    
    // WhatsApp Messages
    final whatsappMessages = settings['whatsappMessages'] ?? {};
    _clientWhatsappController.text = whatsappMessages['clientMessage'] ?? 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.';
    _userWhatsappController.text = whatsappMessages['userMessage'] ?? 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.';
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'حالة العملاء'),
            Tab(text: 'إشعارات العملاء'),
            Tab(text: 'إشعارات المستخدمين'),
            Tab(text: 'رسائل الواتساب'),
            Tab(text: 'الأمان'),
          ],
        ),
      ),
      body: Consumer<SettingsController>(
        builder: (context, settingsController, child) {
          if (settingsController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatusSettingsTab(),
                _buildClientNotificationTab(),
                _buildUserNotificationTab(),
                _buildWhatsappMessagesTab(),
                _buildSecurityTab(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSettings,
        child: Icon(Icons.save),
        tooltip: 'حفظ الإعدادات',
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'إعدادات الأمان',
            'تحكم في خيارات الأمان والمصادقة',
            Icons.security,
          ),
          SizedBox(height: 24),
          
          // Biometric Settings Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fingerprint, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'المصادقة البيومترية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Switch(
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable ? _toggleBiometric : null,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                if (!_biometricAvailable)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'المصادقة البيومترية غير متوفرة على هذا الجهاز',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'تفعيل تسجيل الدخول بالبصمة أو بصمة الوجه',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 12),
                  
                  if (_availableBiometrics.isNotEmpty) ...[
                    Text(
                      'الطرق المتاحة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableBiometrics.map((type) {
                        return Chip(
                          avatar: Icon(
                            _getBiometricIcon(type),
                            size: 16,
                            color: Colors.blue,
                          ),
                          label: Text(
                            BiometricService.getBiometricTypeText(type),
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Additional Security Settings
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shield, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'إعدادات إضافية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                ListTile(
                  leading: Icon(Icons.lock_clock, color: Colors.green),
                  title: Text('مدة انتهاء الجلسة'),
                  subtitle: Text('30 دقيقة'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement session timeout settings
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.password, color: Colors.green),
                  title: Text('سياسة كلمات المرور'),
                  subtitle: Text('6 أحرف كحد أدنى'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement password policy settings
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.history, color: Colors.green),
                  title: Text('سجل العمليات'),
                  subtitle: Text('عرض سجل النشاطات'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement activity log
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.visibility;
      default:
        return Icons.security;
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        await BiometricService.setBiometricEnabled(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تفعيل المصادقة البيومترية'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await BiometricService.disableBiometric();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء تفعيل المصادقة البيومترية'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      setState(() {
        _biometricEnabled = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تغيير إعدادات البصمة: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'إعدادات حالة العملاء',
            'تحديد عدد الأيام لكل حالة من حالات العملاء',
            Icons.traffic,
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _greenDaysController,
                  label: 'أيام الحالة الخضراء',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  controller: _yellowDaysController,
                  label: 'أيام الحالة الصفراء',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildNumberField(
            controller: _redDaysController,
            label: 'أيام الحالة الحمراء',
            icon: Icons.error,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildClientNotificationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'إعدادات إشعارات العملاء',
            'تحديد متى وكم مرة يتم إرسال الإشعارات للعملاء',
            Icons.people,
          ),
          SizedBox(height: 24),
          _buildNotificationTierCard(
            'المستوى الأول - تنبيه عادي',
            _clientTier1DaysController,
            _clientTier1FreqController,
            _clientTier1MessageController,
            Colors.green,
            Icons.info,
          ),
          SizedBox(height: 16),
          _buildNotificationTierCard(
            'المستوى الثاني - تحذير',
            _clientTier2DaysController,
            _clientTier2FreqController,
            _clientTier2MessageController,
            Colors.orange,
            Icons.warning,
          ),
          SizedBox(height: 16),
          _buildNotificationTierCard(
            'المستوى الثالث - عاجل',
            _clientTier3DaysController,
            _clientTier3FreqController,
            _clientTier3MessageController,
            Colors.red,
            Icons.error,
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotificationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'إعدادات إشعارات المستخدمين',
            'تحديد متى وكم مرة يتم إرسال الإشعارات للمستخدمين',
            Icons.admin_panel_settings,
          ),
          SizedBox(height: 24),
          _buildNotificationTierCard(
            'المستوى الأول - تنبيه عادي',
            _userTier1DaysController,
            _userTier1FreqController,
            _userTier1MessageController,
            Colors.green,
            Icons.info,
          ),
          SizedBox(height: 16),
          _buildNotificationTierCard(
            'المستوى الثاني - تحذير',
            _userTier2DaysController,
            _userTier2FreqController,
            _userTier2MessageController,
            Colors.orange,
            Icons.warning,
          ),
          SizedBox(height: 16),
          _buildNotificationTierCard(
            'المستوى الثالث - عاجل',
            _userTier3DaysController,
            _userTier3FreqController,
            _userTier3MessageController,
            Colors.red,
            Icons.error,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsappMessagesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'رسائل الواتساب الافتراضية',
            'النصوص المستخدمة عند إرسال رسائل الواتساب',
            Icons.message,
          ),
          SizedBox(height: 24),
          _buildMessageCard(
            'رسالة العملاء',
            _clientWhatsappController,
            'يمكن استخدام {clientName} في الرسالة',
            Icons.person,
            Colors.blue,
          ),
          SizedBox(height: 16),
          _buildMessageCard(
            'رسالة المستخدمين',
            _userWhatsappController,
            'يمكن استخدام {userName} في الرسالة',
            Icons.admin_panel_settings,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: CustomTextField(
        controller: controller,
        label: label,
        icon: icon,
        keyboardType: TextInputType.number,
        validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildNotificationTierCard(
    String title,
    TextEditingController daysController,
    TextEditingController freqController,
    TextEditingController messageController,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: daysController,
                  label: 'عدد الأيام',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: freqController,
                  label: 'التكرار يومياً',
                  icon: Icons.repeat,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          CustomTextField(
            controller: messageController,
            label: 'نص الرسالة',
            icon: Icons.message,
            maxLines: 3,
            validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    String title,
    TextEditingController controller,
    String hint,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          CustomTextField(
            controller: controller,
            label: 'نص الرسالة',
            icon: Icons.message,
            maxLines: 4,
            validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
          ),
          SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
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
        };

        await settingsController.updateAdminSettings(settings);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعدادات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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