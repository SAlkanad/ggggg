import '../../models/client_model.dart';

class ValidationUtils {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validatePhone(String? value, PhoneCountry country) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (country == PhoneCountry.saudi) {
      if (!RegExp(r'^(5)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم سعودي غير صحيح (يجب أن يبدأ بـ 5 ويكون 9 أرقام)';
      }
    } else if (country == PhoneCountry.yemen) {
      if (!RegExp(r'^(7)[0-9]{8}$').hasMatch(cleanedValue)) {
        return 'رقم يمني غير صحيح (يجب أن يبدأ بـ 7 ويكون 9 أرقام)';
      }
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    
    return null;
  }

  static String? validateNumber(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'يجب أن يكون رقماً صحيحاً';
    }
    
    if (min != null && number < min) {
      return 'يجب أن يكون أكبر من أو يساوي $min';
    }
    
    if (max != null && number > max) {
      return 'يجب أن يكون أصغر من أو يساوي $max';
    }
    
    return null;
  }
}