import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';

class WhatsAppService {
  static Future<void> sendClientMessage({
    required String phoneNumber,
    required PhoneCountry country,
    required String message,
    required String clientName,
  }) async {
    try {
      final countryCode = country == PhoneCountry.saudi ? '966' : '967';
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Remove country code if already present
      if (cleanPhone.startsWith(countryCode)) {
        cleanPhone = cleanPhone.substring(countryCode.length);
      }
      
      // Validate phone format
      if (country == PhoneCountry.saudi && !cleanPhone.startsWith('5')) {
        throw 'رقم سعودي غير صحيح';
      }
      if (country == PhoneCountry.yemen && !cleanPhone.startsWith('7')) {
        throw 'رقم يمني غير صحيح';
      }
      
      final formattedMessage = message.replaceAll('{clientName}', clientName);
      final encodedMessage = Uri.encodeComponent(formattedMessage);
      final url = 'https://wa.me/$countryCode$cleanPhone?text=$encodedMessage';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح الواتساب';
      }
    } catch (e) {
      throw 'خطأ في إرسال رسالة الواتساب: ${e.toString()}';
    }
  }

  static Future<void> sendUserMessage({
    required String phoneNumber,
    required String message,
    required String userName,
  }) async {
    try {
      // Remove country code if present
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      cleanPhone = cleanPhone.replaceAll(RegExp(r'^(\+?966|\+?967)'), '');
      
      // Determine country based on phone pattern
      String countryCode = '966'; // Default to Saudi
      if (cleanPhone.startsWith('7')) {
        countryCode = '967'; // Yemen
      } else if (!cleanPhone.startsWith('5')) {
        // If doesn't start with 5 or 7, assume Saudi and add 5
        cleanPhone = '5$cleanPhone';
      }
      
      final formattedMessage = message.replaceAll('{userName}', userName);
      final encodedMessage = Uri.encodeComponent(formattedMessage);
      final url = 'https://wa.me/$countryCode$cleanPhone?text=$encodedMessage';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح الواتساب';
      }
    } catch (e) {
      throw 'خطأ في إرسال رسالة الواتساب: ${e.toString()}';
    }
  }

  static Future<void> callClient({
    required String phoneNumber,
    required PhoneCountry country,
  }) async {
    try {
      final countryCode = country == PhoneCountry.saudi ? '966' : '967';
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Remove country code if already present
      if (cleanPhone.startsWith(countryCode)) {
        cleanPhone = cleanPhone.substring(countryCode.length);
      }
      
      final url = 'tel:+$countryCode$cleanPhone';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'لا يمكن إجراء المكالمة';
      }
    } catch (e) {
      throw 'خطأ في إجراء المكالمة: ${e.toString()}';
    }
  }

  static Future<void> callUser({
    required String phoneNumber,
  }) async {
    try {
      // Remove country code if present
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      cleanPhone = cleanPhone.replaceAll(RegExp(r'^(\+?966|\+?967)'), '');
      
      // Determine country based on phone pattern
      String countryCode = '966'; // Default to Saudi
      if (cleanPhone.startsWith('7')) {
        countryCode = '967'; // Yemen
      } else if (!cleanPhone.startsWith('5')) {
        // If doesn't start with 5 or 7, assume Saudi and add 5
        cleanPhone = '5$cleanPhone';
      }
      
      final url = 'tel:+$countryCode$cleanPhone';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'لا يمكن إجراء المكالمة';
      }
    } catch (e) {
      throw 'خطأ في إجراء المكالمة: ${e.toString()}';
    }
  }
}