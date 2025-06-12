import 'package:intl/intl.dart';

import 'core.dart';

enum UserRole { admin, user, agency }

class UserModel {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final bool isFrozen;
  final String? freezeReason;
  final DateTime? validationEndDate;
  final DateTime createdAt;
  final String? createdBy;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.name,
    required this.phone,
    required this.email,
    this.isActive = true,
    this.isFrozen = false,
    this.freezeReason,
    this.validationEndDate,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.toString().split('.').last,
      'name': name,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'isFrozen': isFrozen,
      'freezeReason': freezeReason,
      'validationEndDate': validationEndDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.user,
      ),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isActive: map['isActive'] ?? true,
      isFrozen: map['isFrozen'] ?? false,
      freezeReason: map['freezeReason'],
      validationEndDate: map['validationEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['validationEndDate'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      createdBy: map['createdBy'],
    );
  }
}

enum PhoneCountry { saudi, yemen }
enum VisaType { visit, work, umrah, hajj }
enum ClientStatus { green, yellow, red, white }

extension PhoneCountryExtension on PhoneCountry {
  String get displayName {
    switch (this) {
      case PhoneCountry.saudi:
        return 'السعودية';
      case PhoneCountry.yemen:
        return 'اليمن';
    }
  }
  
  String get countryCode {
    switch (this) {
      case PhoneCountry.saudi:
        return '+966';
      case PhoneCountry.yemen:
        return '+967';
    }
  }
  
  String get flag {
    switch (this) {
      case PhoneCountry.saudi:
        return '🇸🇦';
      case PhoneCountry.yemen:
        return '🇾🇪';
    }
  }
}

extension VisaTypeExtension on VisaType {
  String get displayName {
    switch (this) {
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
}

extension ClientStatusExtension on ClientStatus {
  String get displayName {
    switch (this) {
      case ClientStatus.green:
        return 'أخضر';
      case ClientStatus.yellow:
        return 'أصفر';
      case ClientStatus.red:
        return 'أحمر';
      case ClientStatus.white:
        return 'أبيض';
    }
  }
}
// Additional model classes to be added to lib/models.dart
// These classes are referenced in controllers but not defined

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
      greenDays: map['greenDays'] ?? AppConstants.defaultGreenDays,
      yellowDays: map['yellowDays'] ?? AppConstants.defaultYellowDays,
      redDays: map['redDays'] ?? AppConstants.defaultRedDays,
    );
  }

  StatusSettings copyWith({
    int? greenDays,
    int? yellowDays,
    int? redDays,
  }) {
    return StatusSettings(
      greenDays: greenDays ?? this.greenDays,
      yellowDays: yellowDays ?? this.yellowDays,
      redDays: redDays ?? this.redDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusSettings &&
        other.greenDays == greenDays &&
        other.yellowDays == yellowDays &&
        other.redDays == redDays;
  }

  @override
  int get hashCode => greenDays.hashCode ^ yellowDays.hashCode ^ redDays.hashCode;

  @override
  String toString() {
    return 'StatusSettings(greenDays: $greenDays, yellowDays: $yellowDays, redDays: $redDays)';
  }
}

// Additional utility class for managing app-wide configuration
class AppConfiguration {
  final StatusSettings statusSettings;
  final NotificationSettings notificationSettings;
  final Map<String, String> whatsappMessages;
  final Map<String, bool> adminFilters;

  AppConfiguration({
    required this.statusSettings,
    required this.notificationSettings,
    required this.whatsappMessages,
    required this.adminFilters,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientStatusSettings': statusSettings.toMap(),
      'clientNotificationSettings': {
        'firstTier': notificationSettings.clientTiers.isNotEmpty
            ? notificationSettings.clientTiers[0].toMap() : {},
        'secondTier': notificationSettings.clientTiers.length > 1
            ? notificationSettings.clientTiers[1].toMap() : {},
        'thirdTier': notificationSettings.clientTiers.length > 2
            ? notificationSettings.clientTiers[2].toMap() : {},
      },
      'userNotificationSettings': {
        'firstTier': notificationSettings.userTiers.isNotEmpty
            ? notificationSettings.userTiers[0].toMap() : {},
        'secondTier': notificationSettings.userTiers.length > 1
            ? notificationSettings.userTiers[1].toMap() : {},
        'thirdTier': notificationSettings.userTiers.length > 2
            ? notificationSettings.userTiers[2].toMap() : {},
      },
      'whatsappMessages': whatsappMessages,
      'adminFilters': adminFilters,
    };
  }

  factory AppConfiguration.fromMap(Map<String, dynamic> map) {
    // Parse status settings
    final statusMap = map['clientStatusSettings'] ?? {};
    final statusSettings = StatusSettings.fromMap(statusMap);

    // Parse notification settings
    final clientNotificationMap = map['clientNotificationSettings'] ?? {};
    final userNotificationMap = map['userNotificationSettings'] ?? {};

    final clientTiers = [
      NotificationTier.fromMap(clientNotificationMap['firstTier'] ?? {}),
      NotificationTier.fromMap(clientNotificationMap['secondTier'] ?? {}),
      NotificationTier.fromMap(clientNotificationMap['thirdTier'] ?? {}),
    ];

    final userTiers = [
      NotificationTier.fromMap(userNotificationMap['firstTier'] ?? {}),
      NotificationTier.fromMap(userNotificationMap['secondTier'] ?? {}),
      NotificationTier.fromMap(userNotificationMap['thirdTier'] ?? {}),
    ];

    final whatsappMap = map['whatsappMessages'] ?? {};
    final notificationSettings = NotificationSettings(
      clientTiers: clientTiers,
      userTiers: userTiers,
      clientWhatsAppMessage: whatsappMap['clientMessage'] ?? AppConstants.defaultClientMessage,
      userWhatsAppMessage: whatsappMap['userMessage'] ?? AppConstants.defaultUserMessage,
    );

    return AppConfiguration(
      statusSettings: statusSettings,
      notificationSettings: notificationSettings,
      whatsappMessages: Map<String, String>.from(whatsappMap),
      adminFilters: Map<String, bool>.from(map['adminFilters'] ?? {}),
    );
  }

  AppConfiguration copyWith({
    StatusSettings? statusSettings,
    NotificationSettings? notificationSettings,
    Map<String, String>? whatsappMessages,
    Map<String, bool>? adminFilters,
  }) {
    return AppConfiguration(
      statusSettings: statusSettings ?? this.statusSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      whatsappMessages: whatsappMessages ?? this.whatsappMessages,
      adminFilters: adminFilters ?? this.adminFilters,
    );
  }
}

// Extended user profile settings for more granular control
class UserProfileSettings {
  final bool notificationsEnabled;
  final bool whatsappEnabled;
  final bool autoScheduleEnabled;
  final bool biometricEnabled;
  final NotificationFrequency notificationFrequency;
  final Map<String, dynamic> customSettings;

  UserProfileSettings({
    this.notificationsEnabled = true,
    this.whatsappEnabled = true,
    this.autoScheduleEnabled = true,
    this.biometricEnabled = false,
    this.notificationFrequency = NotificationFrequency.normal,
    this.customSettings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'notifications': notificationsEnabled,
      'whatsapp': whatsappEnabled,
      'autoSchedule': autoScheduleEnabled,
      'biometric': biometricEnabled,
      'notificationFrequency': notificationFrequency.toString().split('.').last,
      'customSettings': customSettings,
    };
  }

  factory UserProfileSettings.fromMap(Map<String, dynamic> map) {
    return UserProfileSettings(
      notificationsEnabled: map['notifications'] ?? true,
      whatsappEnabled: map['whatsapp'] ?? true,
      autoScheduleEnabled: map['autoSchedule'] ?? true,
      biometricEnabled: map['biometric'] ?? false,
      notificationFrequency: NotificationFrequency.values.firstWhere(
            (e) => e.toString().split('.').last == map['notificationFrequency'],
        orElse: () => NotificationFrequency.normal,
      ),
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
    );
  }

  UserProfileSettings copyWith({
    bool? notificationsEnabled,
    bool? whatsappEnabled,
    bool? autoScheduleEnabled,
    bool? biometricEnabled,
    NotificationFrequency? notificationFrequency,
    Map<String, dynamic>? customSettings,
  }) {
    return UserProfileSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      autoScheduleEnabled: autoScheduleEnabled ?? this.autoScheduleEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

// Enum for notification frequency settings
enum NotificationFrequency {
  low,     // Once per day
  normal,  // Default frequency based on tier settings
  high,    // More frequent notifications
  urgent   // Maximum frequency for critical notifications
}

extension NotificationFrequencyExtension on NotificationFrequency {
  String get displayName {
    switch (this) {
      case NotificationFrequency.low:
        return 'منخفض';
      case NotificationFrequency.normal:
        return 'عادي';
      case NotificationFrequency.high:
        return 'عالي';
      case NotificationFrequency.urgent:
        return 'عاجل';
    }
  }

  int get multiplier {
    switch (this) {
      case NotificationFrequency.low:
        return 1;
      case NotificationFrequency.normal:
        return 2;
      case NotificationFrequency.high:
        return 3;
      case NotificationFrequency.urgent:
        return 5;
    }
  }
}

// Enhanced client statistics model
class ClientStatistics {
  final int totalClients;
  final int activeClients;
  final int exitedClients;
  final int greenStatusCount;
  final int yellowStatusCount;
  final int redStatusCount;
  final int whiteStatusCount;
  final Map<VisaType, int> clientsByVisaType;
  final Map<PhoneCountry, int> clientsByCountry;
  final DateTime lastUpdated;

  ClientStatistics({
    required this.totalClients,
    required this.activeClients,
    required this.exitedClients,
    required this.greenStatusCount,
    required this.yellowStatusCount,
    required this.redStatusCount,
    required this.whiteStatusCount,
    required this.clientsByVisaType,
    required this.clientsByCountry,
    required this.lastUpdated,
  });

  factory ClientStatistics.fromClients(List<ClientModel> clients) {
    final now = DateTime.now();
    final activeClients = clients.where((c) => !c.hasExited).toList();
    final exitedClients = clients.where((c) => c.hasExited).toList();

    final statusCounts = <ClientStatus, int>{};
    final visaTypeCounts = <VisaType, int>{};
    final countryCounts = <PhoneCountry, int>{};

    for (final client in clients) {
      statusCounts[client.status] = (statusCounts[client.status] ?? 0) + 1;
      visaTypeCounts[client.visaType] = (visaTypeCounts[client.visaType] ?? 0) + 1;
      countryCounts[client.phoneCountry] = (countryCounts[client.phoneCountry] ?? 0) + 1;
    }

    return ClientStatistics(
      totalClients: clients.length,
      activeClients: activeClients.length,
      exitedClients: exitedClients.length,
      greenStatusCount: statusCounts[ClientStatus.green] ?? 0,
      yellowStatusCount: statusCounts[ClientStatus.yellow] ?? 0,
      redStatusCount: statusCounts[ClientStatus.red] ?? 0,
      whiteStatusCount: statusCounts[ClientStatus.white] ?? 0,
      clientsByVisaType: visaTypeCounts,
      clientsByCountry: countryCounts,
      lastUpdated: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalClients': totalClients,
      'activeClients': activeClients,
      'exitedClients': exitedClients,
      'greenStatusCount': greenStatusCount,
      'yellowStatusCount': yellowStatusCount,
      'redStatusCount': redStatusCount,
      'whiteStatusCount': whiteStatusCount,
      'clientsByVisaType': clientsByVisaType.map(
            (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'clientsByCountry': clientsByCountry.map(
            (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory ClientStatistics.fromMap(Map<String, dynamic> map) {
    final visaTypeMap = Map<String, int>.from(map['clientsByVisaType'] ?? {});
    final countryMap = Map<String, int>.from(map['clientsByCountry'] ?? {});

    return ClientStatistics(
      totalClients: map['totalClients'] ?? 0,
      activeClients: map['activeClients'] ?? 0,
      exitedClients: map['exitedClients'] ?? 0,
      greenStatusCount: map['greenStatusCount'] ?? 0,
      yellowStatusCount: map['yellowStatusCount'] ?? 0,
      redStatusCount: map['redStatusCount'] ?? 0,
      whiteStatusCount: map['whiteStatusCount'] ?? 0,
      clientsByVisaType: visaTypeMap.map((key, value) => MapEntry(
        VisaType.values.firstWhere((e) => e.toString().split('.').last == key),
        value,
      )),
      clientsByCountry: countryMap.map((key, value) => MapEntry(
        PhoneCountry.values.firstWhere((e) => e.toString().split('.').last == key),
        value,
      )),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
    );
  }
}
class ClientModel {
  final String id;
  final String clientName;
  final String username;
  final String clientPhone;        // Standardized field name
  final String? secondPhone;       // Standardized field name
  final PhoneCountry phoneCountry;
  final VisaType visaType;
  final String? agentName;
  final String? agentPhone;
  final DateTime entryDate;
  final String notes;
  final List<String> imageUrls;
  final ClientStatus status;
  final int daysRemaining;
  final bool hasExited;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;               // New version field for concurrency control

  ClientModel({
    required this.id,
    required this.clientName,
    required this.username,
    required this.clientPhone,
    this.secondPhone,
    required this.phoneCountry,
    required this.visaType,
    this.agentName,
    this.agentPhone,
    required this.entryDate,
    this.notes = '',
    this.imageUrls = const [],
    this.status = ClientStatus.green,
    this.daysRemaining = 0,
    this.hasExited = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,               // Default version starts at 1
  });

  String get fullPrimaryPhone => '${phoneCountry.countryCode}$clientPhone';
  String get fullSecondaryPhone => secondPhone != null
      ? '${phoneCountry.countryCode}$secondPhone'
      : '';

  String get statusDisplayName => status.displayName;
  String get visaDisplayName => visaType.displayName;
  String get countryDisplayName => phoneCountry.displayName;

  String get formattedEntryDate => DateFormat('yyyy-MM-dd').format(entryDate);
  String get formattedCreatedAt => DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'username': username,
      'clientPhone': clientPhone,           // Updated field name
      'secondPhone': secondPhone,           // Updated field name
      'phoneCountry': phoneCountry.toString().split('.').last,
      'visaType': visaType.toString().split('.').last,
      'agentName': agentName,
      'agentPhone': agentPhone,
      'entryDate': entryDate.millisecondsSinceEpoch,
      'notes': notes,
      'imageUrls': imageUrls,
      'status': status.toString().split('.').last,
      'daysRemaining': daysRemaining,
      'hasExited': hasExited,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'version': version,                   // Include version in serialization
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      clientName: map['clientName'] ?? '',
      username: map['username'] ?? '',
      clientPhone: map['clientPhone'] ?? '',        // Updated field name
      secondPhone: map['secondPhone'],               // Updated field name
      phoneCountry: PhoneCountry.values.firstWhere(
            (e) => e.toString().split('.').last == map['phoneCountry'],
        orElse: () => PhoneCountry.saudi,
      ),
      visaType: VisaType.values.firstWhere(
            (e) => e.toString().split('.').last == map['visaType'],
        orElse: () => VisaType.umrah,
      ),
      agentName: map['agentName'],
      agentPhone: map['agentPhone'],
      entryDate: DateTime.fromMillisecondsSinceEpoch(map['entryDate']),
      notes: map['notes'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: ClientStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
        orElse: () => ClientStatus.green,
      ),
      daysRemaining: map['daysRemaining'] ?? 0,
      hasExited: map['hasExited'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      version: map['version'] ?? 1,                 // Handle existing data without version
    );
  }

  String get fullClientPhone => fullPrimaryPhone;

  ClientModel copyWith({
    String? id,
    String? clientName,
    String? username,
    String? clientPhone,
    String? secondPhone,
    PhoneCountry? phoneCountry,
    VisaType? visaType,
    String? agentName,
    String? agentPhone,
    DateTime? entryDate,
    String? notes,
    List<String>? imageUrls,
    ClientStatus? status,
    int? daysRemaining,
    bool? hasExited,
    DateTime? updatedAt,
    int? version,                               // Allow version updates
  }) {
    return ClientModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      username: username ?? this.username,
      clientPhone: clientPhone ?? this.clientPhone,
      secondPhone: secondPhone ?? this.secondPhone,
      phoneCountry: phoneCountry ?? this.phoneCountry,
      visaType: visaType ?? this.visaType,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      entryDate: entryDate ?? this.entryDate,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      hasExited: hasExited ?? this.hasExited,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      version: version ?? this.version,           // Maintain current version unless explicitly updated
    );
  }
}

enum NotificationType { clientExpiring, userValidationExpiring }
enum NotificationPriority { high, medium, low }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String targetUserId;
  final String? clientId;
  final bool isRead;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.targetUserId,
    this.clientId,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
    required this.createdAt,
    this.scheduledFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'targetUserId': targetUserId,
      'clientId': clientId,
      'isRead': isRead,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'scheduledFor': scheduledFor?.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.clientExpiring,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      clientId: map['clientId'],
      isRead: map['isRead'] ?? false,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      scheduledFor: map['scheduledFor'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledFor'])
          : null,
    );
  }
}

class StatusUpdateConfig {
  final int greenDays;
  final int yellowDays;
  final int redDays;

  StatusUpdateConfig({
    this.greenDays = 30,
    this.yellowDays = 30,
    this.redDays = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'greenDays': greenDays,
      'yellowDays': yellowDays,
      'redDays': redDays,
    };
  }

  factory StatusUpdateConfig.fromMap(Map<String, dynamic> map) {
    return StatusUpdateConfig(
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

class ClientFilter {
  final String? userFilter;
  final ClientStatus? statusFilter;
  final VisaType? visaTypeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  ClientFilter({
    this.userFilter,
    this.statusFilter,
    this.visaTypeFilter,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  ClientFilter copyWith({
    String? userFilter,
    ClientStatus? statusFilter,
    VisaType? visaTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return ClientFilter(
      userFilter: userFilter ?? this.userFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      visaTypeFilter: visaTypeFilter ?? this.visaTypeFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return userFilter != null ||
        statusFilter != null ||
        visaTypeFilter != null ||
        startDate != null ||
        endDate != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  ClientFilter clear() {
    return ClientFilter();
  }
}

class BiometricInfo {
  final bool isAvailable;
  final bool isEnabled;
  final List<String> availableTypes;

  BiometricInfo({
    required this.isAvailable,
    required this.isEnabled,
    required this.availableTypes,
  });

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'isEnabled': isEnabled,
      'availableTypes': availableTypes,
    };
  }

  factory BiometricInfo.fromMap(Map<String, dynamic> map) {
    return BiometricInfo(
      isAvailable: map['isAvailable'] ?? false,
      isEnabled: map['isEnabled'] ?? false,
      availableTypes: List<String>.from(map['availableTypes'] ?? []),
    );
  }
}

class CacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static void put(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _cache[key] as T?;
    }
    return null;
  }

  static void clear([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  static void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiry)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}