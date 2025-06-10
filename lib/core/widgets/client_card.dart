import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../services/whatsapp_service.dart';
import 'status_card.dart';

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(ClientStatus)? onStatusChange;
  final VoidCallback? onViewImages;

  const ClientCard({
    Key? key,
    required this.client,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.onViewImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client.clientName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusCard(
                  status: client.status,
                  daysRemaining: client.daysRemaining,
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Primary phone
            if (client.clientPhone.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('الهاتف الأساسي: ${client.clientPhone}'),
                ],
              ),
            
            // Secondary phone
            if (client.clientPhone2 != null && client.clientPhone2!.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('الهاتف الثانوي: ${client.clientPhone2}'),
                ],
              ),
            ],
            
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.card_membership, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('نوع التأشيرة: ${_getVisaTypeText(client.visaType)}'),
              ],
            ),
            
            if (client.agentName != null && client.agentName!.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.support_agent, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('الوكيل: ${client.agentName}'),
                ],
              ),
            ],
            
            // Show if client has exited
            if (client.hasExited && client.exitDate != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flight_takeoff, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'تاريخ الخروج: ${client.exitDate!.day}/${client.exitDate!.month}/${client.exitDate!.year}',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 12),
            
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                // WhatsApp buttons for all phone numbers
                if (!client.hasExited && client.clientPhone.isNotEmpty)
                  _buildPhoneActionButton(
                    context,
                    client.clientPhone,
                    client.phoneCountry,
                    'الأساسي',
                    true,
                  ),
                
                if (!client.hasExited && client.clientPhone2 != null && client.clientPhone2!.isNotEmpty)
                  _buildPhoneActionButton(
                    context,
                    client.clientPhone2!,
                    client.phoneCountry2!,
                    'الثانوي',
                    false,
                  ),
                
                // View images button
                if (onViewImages != null && _hasImages())
                  ActionChip(
                    avatar: Icon(Icons.photo, size: 16),
                    label: Text('الصور'),
                    onPressed: onViewImages,
                    backgroundColor: Colors.purple.shade100,
                  ),
                
                // Edit button
                if (onEdit != null)
                  ActionChip(
                    avatar: Icon(Icons.edit, size: 16),
                    label: Text('تعديل'),
                    onPressed: onEdit,
                    backgroundColor: Colors.orange.shade100,
                  ),
                
                // Exit status button
                if (onStatusChange != null && !client.hasExited)
                  ActionChip(
                    avatar: Icon(Icons.exit_to_app, size: 16),
                    label: Text('خرج'),
                    onPressed: () => onStatusChange!(ClientStatus.white),
                    backgroundColor: Colors.grey.shade100,
                  ),
                
                // Delete button
                if (onDelete != null)
                  ActionChip(
                    avatar: Icon(Icons.delete, size: 16),
                    label: Text('حذف'),
                    onPressed: () => _confirmDelete(context),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneActionButton(
    BuildContext context,
    String phone,
    PhoneCountry country,
    String label,
    bool isPrimary,
  ) {
    return PopupMenuButton<String>(
      child: ActionChip(
        avatar: Icon(
          isPrimary ? Icons.phone : Icons.phone_android,
          size: 16,
        ),
        label: Text(label),
        backgroundColor: Colors.green.shade100,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'whatsapp',
          child: Row(
            children: [
              Icon(Icons.message, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('واتساب'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'call',
          child: Row(
            children: [
              Icon(Icons.call, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('اتصال'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'whatsapp') {
          _sendWhatsApp(context, phone, country);
        } else if (value == 'call') {
          _makeCall(phone, country);
        }
      },
    );
  }

  bool _hasImages() {
    return (client.visaImageUrl != null && client.visaImageUrl!.isNotEmpty) ||
           (client.passportImageUrl != null && client.passportImageUrl!.isNotEmpty);
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

  void _sendWhatsApp(BuildContext context, String phone, PhoneCountry country) async {
    try {
      await WhatsAppService.sendClientMessage(
        phoneNumber: phone,
        country: country,
        message: 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً.',
        clientName: client.clientName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في فتح الواتساب: ${e.toString()}')),
      );
    }
  }

  void _makeCall(String phone, PhoneCountry country) async {
    try {
      await WhatsAppService.callClient(
        phoneNumber: phone,
        country: country,
      );
    } catch (e) {
      // Handle error silently or show message
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا العميل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}