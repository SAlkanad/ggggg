import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/custom_text_field.dart';

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
  
  // Profile Settings
  bool _notificationsEnabled = true;
  bool _whatsappEnabled = true;
  bool _autoScheduleEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final settingsController = Provider.of<SettingsController>(context, listen: false);
    await settingsController.loadUserSettings(authController.currentUser!.id);
    _populateFields();
  }

  void _populateFields() {
    final settings = Provider.of<SettingsController>(context, listen: false).userSettings;
    
    // Status Settings
    final statusSettings = settings['clientStatusSettings'] ?? {};
    _greenDaysController.text = (statusSettings['greenDays'] ?? 30).toString();
    _yellowDaysController.text = (statusSettings['yellowDays'] ?? 30).toString();
    _redDaysController.text = (statusSettings['redDays'] ?? 1).toString();
    
    // Notification Settings
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
    
    // WhatsApp Message
    _whatsappMessageController.text = settings['whatsappMessage'] ?? 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.';
    
    // Profile Settings
    final profile = settings['profile'] ?? {};
    _notificationsEnabled = profile['notifications'] ?? true;
    _whatsappEnabled = profile['whatsapp'] ?? true;
    _autoScheduleEnabled = profile['autoSchedule'] ?? true;
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('حفظ الإعدادات', style: TextStyle(fontSize: 18)),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إعدادات الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('تفعيل الإشعارات'),
              subtitle: Text('استقبال إشعارات انتهاء التأشيرات'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            SwitchListTile(
              title: Text('تفعيل الواتساب'),
              subtitle: Text('إمكانية إرسال رسائل واتساب'),
              value: _whatsappEnabled,
              onChanged: (value) => setState(() => _whatsappEnabled = value),
            ),
            SwitchListTile(
              title: Text('الجدولة التلقائية'),
              subtitle: Text('جدولة الإشعارات تلقائياً'),
              value: _autoScheduleEnabled,
              onChanged: (value) => setState(() => _autoScheduleEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSettingsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إعدادات حالة العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _greenDaysController,
                    label: 'أيام الحالة الخضراء',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _yellowDaysController,
                    label: 'أيام الحالة الصفراء',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _redDaysController,
                    label: 'أيام الحالة الحمراء',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إعدادات الإشعارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildNotificationTier('المستوى الأول', _tier1DaysController, _tier1FreqController, _tier1MessageController),
            SizedBox(height: 16),
            _buildNotificationTier('المستوى الثاني', _tier2DaysController, _tier2FreqController, _tier2MessageController),
            SizedBox(height: 16),
            _buildNotificationTier('المستوى الثالث', _tier3DaysController, _tier3FreqController, _tier3MessageController),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTier(String title, TextEditingController daysController, TextEditingController freqController, TextEditingController messageController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: daysController,
                label: 'الأيام',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                controller: freqController,
                label: 'التكرار يومياً',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CustomTextField(
          controller: messageController,
          label: 'نص الرسالة',
          maxLines: 2,
          validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
        ),
      ],
    );
  }

  Widget _buildWhatsappMessageCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رسالة الواتساب الافتراضية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            CustomTextField(
              controller: _whatsappMessageController,
              label: 'نص الرسالة',
              maxLines: 3,
              validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
            ),
            SizedBox(height: 8),
            Text(
              'يمكن استخدام {clientName} في الرسالة',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
          },
        };

        await settingsController.updateUserSettings(authController.currentUser!.id, settings);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الإعدادات: ${e.toString()}')),
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
