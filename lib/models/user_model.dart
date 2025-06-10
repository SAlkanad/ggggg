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
