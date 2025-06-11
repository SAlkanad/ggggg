import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'controllers.dart';
import 'services.dart';
import 'core.dart';

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
                  Icon(Icons.person_pin, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text('إعدادات إشعارات العملاء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الأول', _clientTier1DaysController, _clientTier1FreqController, _clientTier1MessageController, Colors.green),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثاني', _clientTier2DaysController, _clientTier2FreqController, _clientTier2MessageController, Colors.orange),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثالث', _clientTier3DaysController, _clientTier3FreqController, _clientTier3MessageController, Colors.red),
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
                  Icon(Icons.group, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('إعدادات إشعارات المستخدمين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                ],
              ),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الأول', _userTier1DaysController, _userTier1FreqController, _userTier1MessageController, Colors.green),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثاني', _userTier2DaysController, _userTier2FreqController, _userTier2MessageController, Colors.orange),
              SizedBox(height: 16),
              _buildNotificationTier('المستوى الثالث', _userTier3DaysController, _userTier3FreqController, _userTier3MessageController, Colors.red),
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
                  Icon(Icons.chat, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('رسائل الواتساب الافتراضية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
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
                ),
                validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _userWhatsappController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'رسالة المستخدمين',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.group, color: Colors.green),
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
          'adminFilters': {
            'showOnlyMyClients': _showOnlyMyClients,
            'showOnlyMyNotifications': _showOnlyMyNotifications,
          },
        };

        await settingsController.updateAdminSettings(settings);
        await settingsController.updateAdminFilters(_showOnlyMyClients, _showOnlyMyNotifications);
        
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

class UserSettingsScreen extends StatefulWidget {
  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _greenDaysController = TextEditingController();
  final _yellowDaysController = TextEditingController();
  final _redDaysController = TextEditingController();
  
  final _tier1DaysController = TextEditingController();
  final _tier1FreqController = TextEditingController();
  final _tier1MessageController = TextEditingController();
  final _tier2DaysController = TextEditingController();
  final _tier2FreqController = TextEditingController();
  final _tier2MessageController = TextEditingController();
  final _tier3DaysController = TextEditingController();
  final _tier3FreqController = TextEditingController();
  final _tier3MessageController = TextEditingController();
  
  final _whatsappMessageController = TextEditingController();
  
  bool _notificationsEnabled = true;
  bool _whatsappEnabled = true;
  bool _autoScheduleEnabled = true;
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
    final authController = Provider.of<AuthController>(context, listen: false);
    final settingsController = Provider.of<SettingsController>(context, listen: false);
    await settingsController.loadUserSettings(authController.currentUser!.id);
    _populateFields();
  }

  Future<void> _checkBiometricStatus() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    setState(() {
      _biometricEnabled = authController.biometricEnabled;
    });
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).userSettings;
    
    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? 30).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? 30).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? 1).toString();
    
    final notificationSettings = settings['notificationSettings'] ?? {};
    final tier1 = notificationSettings['firstTier'] ?? {};
    final tier2 = notificationSettings['secondTier'] ?? {};
    final tier3 = notificationSettings['thirdTier'] ?? {};
    
    _tier1DaysController.text = (tier1['days'] ?? 10).toString();
    _tier1FreqController.text = (tier1['frequency'] ?? 2).toString();
    _tier1MessageController.text = tier1['message'] ?? 'تنبيه: تنتهي تأشيرة العميل {clientName} خلال 10 أيام';
    
    _tier2DaysController.text = (tier2['days'] ?? 5).toString();
    _tier2FreqController.text = (tier2['frequency'] ?? 4).toString();
    _tier2MessageController.text = tier2['message'] ?? 'تحذير: تنتهي تأشيرة العميل {clientName} خلال 5 أيام';
    
    _tier3DaysController.text = (tier3['days'] ?? 2).toString();
    _tier3FreqController.text = (tier3['frequency'] ?? 8).toString();
    _tier3MessageController.text = tier3['message'] ?? 'عاجل: تنتهي تأشيرة العميل {clientName} خلال يومين';
    
    _whatsappMessageController.text = settings['whatsappMessage'] ?? 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.';
    
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
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: Text('حفظ الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Icon(Icons.person, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text('إعدادات الملف الشخصي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
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
              _buildSwitchTile(
                'تفعيل الواتساب',
                'إمكانية إرسال رسائل واتساب',
                Icons.message,
                Colors.green,
                _whatsappEnabled,
                (value) => setState(() => _whatsappEnabled = value),
              ),
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
                  Icon(Icons.fingerprint, color: Colors.indigo, size: 28),
                  SizedBox(width: 12),
                  Text('المصادقة البيومترية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                ],
              ),
              SizedBox(height: 16),
              _buildSwitchTile(
                'تفعيل بصمة الإصبع',
                'استخدم بصمة الإصبع لتسجيل الدخول السريع',
                Icons.security,
                Colors.indigo,
                _biometricEnabled,
                (value) async {
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