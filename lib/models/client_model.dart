enum PhoneCountry { saudi, yemen }
enum VisaType { visit, work, umrah, hajj }
enum ClientStatus { green, yellow, red, white }

class ClientModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final String? clientPhone2; // Additional phone number
  final PhoneCountry phoneCountry;
  final PhoneCountry? phoneCountry2; // Country for additional phone
  final VisaType visaType;
  final String? agentName;
  final String? agentPhone;
  final DateTime entryDate;
  final String notes;
  final String? visaImageUrl;
  final String? passportImageUrl;
  final ClientStatus status;
  final int daysRemaining;
  final bool hasExited;
  final DateTime? exitDate; // When client exited
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    this.clientPhone2,
    required this.phoneCountry,
    this.phoneCountry2,
    required this.visaType,
    this.agentName,
    this.agentPhone,
    required this.entryDate,
    required this.notes,
    this.visaImageUrl,
    this.passportImageUrl,
    required this.status,
    required this.daysRemaining,
    this.hasExited = false,
    this.exitDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientPhone2': clientPhone2,
      'phoneCountry': phoneCountry.toString().split('.').last,
      'phoneCountry2': phoneCountry2?.toString().split('.').last,
      'visaType': visaType.toString().split('.').last,
      'agentName': agentName,
      'agentPhone': agentPhone,
      'entryDate': entryDate.millisecondsSinceEpoch,
      'notes': notes,
      'visaImageUrl': visaImageUrl,
      'passportImageUrl': passportImageUrl,
      'status': status.toString().split('.').last,
      'daysRemaining': daysRemaining,
      'hasExited': hasExited,
      'exitDate': exitDate?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientPhone2: map['clientPhone2'],
      phoneCountry: PhoneCountry.values.firstWhere(
        (e) => e.toString().split('.').last == map['phoneCountry'],
        orElse: () => PhoneCountry.saudi,
      ),
      phoneCountry2: map['phoneCountry2'] != null
          ? PhoneCountry.values.firstWhere(
              (e) => e.toString().split('.').last == map['phoneCountry2'],
              orElse: () => PhoneCountry.saudi,
            )
          : null,
      visaType: VisaType.values.firstWhere(
        (e) => e.toString().split('.').last == map['visaType'],
        orElse: () => VisaType.umrah,
      ),
      agentName: map['agentName'],
      agentPhone: map['agentPhone'],
      entryDate: DateTime.fromMillisecondsSinceEpoch(map['entryDate']),
      notes: map['notes'] ?? '',
      visaImageUrl: map['visaImageUrl'],
      passportImageUrl: map['passportImageUrl'],
      status: ClientStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ClientStatus.green,
      ),
      daysRemaining: map['daysRemaining'] ?? 0,
      hasExited: map['hasExited'] ?? false,
      exitDate: map['exitDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['exitDate'])
          : null,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ClientModel copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    String? clientPhone2,
    PhoneCountry? phoneCountry,
    PhoneCountry? phoneCountry2,
    VisaType? visaType,
    String? agentName,
    String? agentPhone,
    DateTime? entryDate,
    String? notes,
    String? visaImageUrl,
    String? passportImageUrl,
    ClientStatus? status,
    int? daysRemaining,
    bool? hasExited,
    DateTime? exitDate,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientPhone2: clientPhone2 ?? this.clientPhone2,
      phoneCountry: phoneCountry ?? this.phoneCountry,
      phoneCountry2: phoneCountry2 ?? this.phoneCountry2,
      visaType: visaType ?? this.visaType,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      entryDate: entryDate ?? this.entryDate,
      notes: notes ?? this.notes,
      visaImageUrl: visaImageUrl ?? this.visaImageUrl,
      passportImageUrl: passportImageUrl ?? this.passportImageUrl,
      status: status ?? this.status,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      hasExited: hasExited ?? this.hasExited,
      exitDate: exitDate ?? this.exitDate,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper method to get all phone numbers
  List<String> getAllPhones() {
    List<String> phones = [];
    if (clientPhone.isNotEmpty) phones.add(clientPhone);
    if (clientPhone2 != null && clientPhone2!.isNotEmpty) phones.add(clientPhone2!);
    return phones;
  }

  // Helper method to search in client data
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return clientName.toLowerCase().contains(lowerQuery) ||
           clientPhone.contains(query) ||
           (clientPhone2?.contains(query) ?? false) ||
           (agentName?.toLowerCase().contains(lowerQuery) ?? false);
  }
}