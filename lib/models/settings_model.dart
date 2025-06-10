class StatusSettings {
  final int greenDays;
  final int yellowDays;
  final int redDays;

  StatusSettings({
    required this.greenDays,
    required this.yellowDays,
    required this.redDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'greenDays': greenDays,
      'yellowDays': yellowDays,
      'redDays': redDays,
    };
  }

  factory StatusSettings.fromMap(Map<String, dynamic> map) {
    return StatusSettings(
      greenDays: map['greenDays'] ?? 30,
      yellowDays: map['yellowDays'] ?? 30,
      redDays: map['redDays'] ?? 1,
    );
  }
}

class NotificationTier {
  final int days;
  final int frequency;
  final String message;

  NotificationTier({
    required this.days,
    required this.frequency,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'frequency': frequency,
      'message': message,
    };
  }

  factory NotificationTier.fromMap(Map<String, dynamic> map) {
    return NotificationTier(
      days: map['days'] ?? 0,
      frequency: map['frequency'] ?? 1,
      message: map['message'] ?? '',
    );
  }
}

class NotificationSettings {
  final List<NotificationTier> clientTiers;
  final List<NotificationTier> userTiers;
  final String clientWhatsAppMessage;
  final String userWhatsAppMessage;

  NotificationSettings({
    required this.clientTiers,
    required this.userTiers,
    required this.clientWhatsAppMessage,
    required this.userWhatsAppMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientTiers': clientTiers.map((tier) => tier.toMap()).toList(),
      'userTiers': userTiers.map((tier) => tier.toMap()).toList(),
      'clientWhatsAppMessage': clientWhatsAppMessage,
      'userWhatsAppMessage': userWhatsAppMessage,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      clientTiers: (map['clientTiers'] as List? ?? [])
          .map((tier) => NotificationTier.fromMap(tier))
          .toList(),
      userTiers: (map['userTiers'] as List? ?? [])
          .map((tier) => NotificationTier.fromMap(tier))
          .toList(),
      clientWhatsAppMessage: map['clientWhatsAppMessage'] ?? '',
      userWhatsAppMessage: map['userWhatsAppMessage'] ?? '',
    );
  }
}
