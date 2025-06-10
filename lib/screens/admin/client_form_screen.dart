import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/client_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/client_controller.dart';
import '../../services/database_service.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/validation_utils.dart';
import '../../core/utils/status_calculator.dart';
import '../../core/utils/date_utils.dart' as AppDateUtils;

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
  final _clientPhone2Controller = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  PhoneCountry _phoneCountry = PhoneCountry.saudi;
  PhoneCountry _phoneCountry2 = PhoneCountry.saudi;
  VisaType _visaType = VisaType.umrah;
  DateTime _entryDate = DateTime.now();
  File? _visaImage;
  File? _passportImage;
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
    _clientPhone2Controller.text = client.clientPhone2 ?? '';
    _phoneCountry = client.phoneCountry;
    _phoneCountry2 = client.phoneCountry2 ?? PhoneCountry.saudi;
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
            icon: Icon(Icons.sync),
            onPressed: _refreshData,
          ),
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

              // Primary Phone
              Text(
                'الهاتف الأساسي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
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

              // Secondary Phone
              Text(
                'الهاتف الثانوي (اختياري)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PhoneCountry>(
                      value: _phoneCountry2,
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
                        setState(() => _phoneCountry2 = value!);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _clientPhone2Controller,
                      label: 'الرقم الثاني',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        return ValidationUtils.validatePhone(value, _phoneCountry2);
                      },
                    ),
                  ),
                ],
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
                  subtitle: Text(AppDateUtils.formatArabicDate(_entryDate)),
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

              Row(
                children: [
                  Expanded(
                    child: _buildImageUpload(
                      title: 'صورة التأشيرة',
                      image: _visaImage,
                      onTap: () => _pickImage(ImageType.visa),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildImageUpload(
                      title: 'صورة الجواز/الإقامة',
                      image: _passportImage,
                      onTap: () => _pickImage(ImageType.passport),
                    ),
                  ),
                ],
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

  Widget _buildImageUpload({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
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

  Future<void> _pickImage(ImageType type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        if (type == ImageType.visa) {
          _visaImage = File(image.path);
        } else {
          _passportImage = File(image.path);
        }
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final settingsController = Provider.of<SettingsController>(context, listen: false);
      await settingsController.loadAdminSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث البيانات')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final authController = Provider.of<AuthController>(context, listen: false);
        final settingsController = Provider.of<SettingsController>(context, listen: false);
        final clientController = Provider.of<ClientController>(context, listen: false);
        
        final settings = settingsController.adminSettings;
        final statusSettings = settings['clientStatusSettings'] ?? {};
        final greenDays = statusSettings['greenDays'] ?? 30;
        final yellowDays = statusSettings['yellowDays'] ?? 30;
        final redDays = statusSettings['redDays'] ?? 1;
        
        final client = ClientModel(
          id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          clientName: _clientNameController.text,
          clientPhone: _clientPhoneController.text,
          clientPhone2: _clientPhone2Controller.text.isEmpty ? null : _clientPhone2Controller.text,
          phoneCountry: _phoneCountry,
          phoneCountry2: _clientPhone2Controller.text.isEmpty ? null : _phoneCountry2,
          visaType: _visaType,
          agentName: _agentNameController.text.isEmpty ? null : _agentNameController.text,
          agentPhone: _agentPhoneController.text.isEmpty ? null : _agentPhoneController.text,
          entryDate: _entryDate,
          notes: _notesController.text,
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

        await DatabaseService.saveClient(client, _visaImage, _passportImage);
        
        // Update controller
        if (widget.client == null) {
          await clientController.addClient(client);
        } else {
          await clientController.updateClient(client);
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
    _clientPhone2Controller.dispose();
    _agentNameController.dispose();
    _agentPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

enum ImageType { visa, passport }