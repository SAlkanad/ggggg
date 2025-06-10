class MessageTemplates {
  // Client notification messages
  static const Map<String, String> clientMessages = {
    'tier1': 'تنبيه: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. يرجى التواصل معنا.',
    'tier2': 'تحذير: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. يرجى التواصل معنا فوراً.',
    'tier3': 'عاجل: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام. اتصل بنا على الفور.',
    'expired': 'عزيزي العميل {clientName}، انتهت صلاحية تأشيرتك. يجب مراجعتنا فوراً.',
  };
  
  // User validation messages
  static const Map<String, String> userMessages = {
    'tier1': 'تنبيه: ينتهي حسابك خلال {daysRemaining} أيام. يرجى التجديد.',
    'tier2': 'تحذير: ينتهي حسابك خلال {daysRemaining} أيام. يرجى التجديد فوراً.',
    'tier3': 'عاجل: ينتهي حسابك خلال {daysRemaining} أيام. يجب التجديد فوراً.',
    'validation_expired': 'انتهت صلاحية حسابك. تم تجميد الحساب.',
    'freeze_notification': 'تم تجميد حسابك. السبب: {reason}',
    'unfreeze_notification': 'تم إلغاء تجميد حسابك. يمكنك الآن استخدام النظام.',
  };
  
  // WhatsApp default messages
  static const Map<String, String> whatsappMessages = {
    'client_default': 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.',
    'client_urgent': 'عاجل: عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك خلال {daysRemaining} أيام.',
    'user_default': 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.',
    'admin_broadcast': 'إشعار عام من إدارة النظام: {message}',
  };
  
  // Notification titles
  static const Map<String, String> notificationTitles = {
    'client_expiring': 'تنبيه انتهاء تأشيرة',
    'client_critical': 'تحذير عاجل - انتهاء تأشيرة',
    'client_expired': 'تأشيرة منتهية الصلاحية',
    'user_validation': 'تنبيه انتهاء صلاحية الحساب',
    'user_freeze': 'تم تجميد الحساب',
    'user_unfreeze': 'تم إلغاء تجميد الحساب',
    'system_announcement': 'إعلان من النظام',
  };
  
  // Status descriptions
  static const Map<String, String> statusDescriptions = {
    'green': 'الوضع آمن - لا توجد مخاطر في الوقت الحالي',
    'yellow': 'تحذير - تنتهي التأشيرة قريباً',
    'red': 'خطر - تنتهي التأشيرة خلال أيام قليلة',
    'white': 'خرج - تم تسجيل خروج العميل',
  };
  
  // Helper method to format message with variables
  static String formatMessage(String template, Map<String, String> variables) {
    String formatted = template;
    variables.forEach((key, value) {
      formatted = formatted.replaceAll('{$key}', value);
    });
    return formatted;
  }
}