import '../../models/client_model.dart';

class PhoneUtils {
  static String formatSaudiNumber(String phone) {
    // Remove any existing country codes and non-digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(\+?966)'), '');
    
    // Ensure it starts with 5 for Saudi mobile numbers
    if (!cleaned.startsWith('5')) {
      cleaned = '5$cleaned';
    }
    
    return '966$cleaned';
  }
  
  static String formatYemeniNumber(String phone) {
    // Remove any existing country codes and non-digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(\+?967)'), '');
    
    // Ensure it starts with 7 for Yemeni mobile numbers
    if (!cleaned.startsWith('7')) {
      cleaned = '7$cleaned';
    }
    
    return '967$cleaned';
  }
  
  static String getFormattedNumber(String phone, PhoneCountry country) {
    switch (country) {
      case PhoneCountry.saudi:
        return formatSaudiNumber(phone);
      case PhoneCountry.yemen:
        return formatYemeniNumber(phone);
    }
  }
  
  static String getDisplayNumber(String phone, PhoneCountry country) {
    final formatted = getFormattedNumber(phone, country);
    if (country == PhoneCountry.saudi) {
      return '+966 ${formatted.substring(3)}';
    } else {
      return '+967 ${formatted.substring(3)}';
    }
  }
  
  static bool isValidSaudiNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^(966)?5[0-9]{8}$').hasMatch(cleaned);
  }
  
  static bool isValidYemeniNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^(967)?7[0-9]{8}$').hasMatch(cleaned);
  }
}