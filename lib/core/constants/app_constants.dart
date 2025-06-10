class AppConstants {
  static const String appName = 'نظام إدارة تأشيرات العمرة';
  static const String appVersion = '1.0.0';
  
  // Default notification settings
  static const int defaultGreenDays = 30;
  static const int defaultYellowDays = 30;
  static const int defaultRedDays = 1;
  
  // Default notification tiers
  static const int firstTierDays = 10;
  static const int firstTierFrequency = 2;
  static const int secondTierDays = 5;
  static const int secondTierFrequency = 4;
  static const int thirdTierDays = 2;
  static const int thirdTierFrequency = 8;
  
  // User notification defaults
  static const int userFirstTierFreq = 1;
  static const int userSecondTierFreq = 1;
  static const int userThirdTierFreq = 1;
  
  // Default messages
  static const String defaultClientMessage = 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.';
  static const String defaultUserMessage = 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.';
}
