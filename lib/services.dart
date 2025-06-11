import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'models.dart';
import 'core.dart';

// services/auth_service.dart
class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserModel> login(String username, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      userData['id'] = userDoc.id;

      final user = UserModel.fromMap(userData);

      if (!user.isActive) {
        throw Exception('الحساب غير مفعل');
      }

      if (user.isFrozen) {
        throw Exception('تم تجميد الحساب: ${user.freezeReason ?? 'غير محدد'}');
      }

      if (user.validationEndDate != null && user.validationEndDate!.isBefore(DateTime.now())) {
        throw Exception('انتهت صلاحية الحساب');
      }

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> saveCredentials(String username, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
      await prefs.setBool('auto_login', true);
    } else {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
      await prefs.setBool('auto_login', false);
    }
  }

  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('saved_username'),
      'password': prefs.getString('saved_password'),
    };
  }

  static Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_login') ?? false;
  }

  static Future<UserModel?> checkAutoLogin() async {
    try {
      if (await shouldAutoLogin()) {
        final credentials = await getSavedCredentials();
        final username = credentials['username'];
        final password = credentials['password'];

        if (username != null && password != null) {
          return await login(username, password);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login', false);
  }

  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Add method to create default admin
  static Future<void> createDefaultAdmin() async {
    try {
      // Check if admin already exists
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create default admin user
        final adminUser = UserModel(
          id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
          username: 'admin',
          password: _hashPassword('admin123'), // Change this password!
          role: UserRole.admin,
          name: 'مدير النظام',
          phone: '966500000000',
          email: 'admin@example.com',
          isActive: true,
          isFrozen: false,
          validationEndDate: DateTime.now().add(Duration(days: 365 * 10)), // 10 years
          createdAt: DateTime.now(),
          createdBy: 'system',
        );

        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(adminUser.id)
            .set(adminUser.toMap());

        print('✅ Default admin user created');
        print('Username: admin');
        print('Password: admin123');
        print('⚠️  Please change the password after first login!');
      } else {
        print('👤 Admin user already exists');
      }
    } catch (e) {
      print('❌ Error creating admin user: $e');
    }
  }
}

// services/database_service.dart
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Client operations
  static Future<void> saveClient(ClientModel client, List<File>? images) async {
    try {
      List<String> imageUrls = [];

      if (images != null && images.isNotEmpty) {
        imageUrls = await ImageService.uploadImages(images, client.id);
      }

      final updatedClient = client.copyWith(
        imageUrls: [...client.imageUrls, ...imageUrls],
      );

      await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(client.id)
          .set(updatedClient.toMap());
    } catch (e) {
      throw Exception('خطأ في حفظ العميل: ${e.toString()}');
    }
  }

  static Future<List<ClientModel>> getClientsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ClientModel.fromMap(data);
      })
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب العملاء: ${e.toString()}');
    }
  }

  static Future<List<ClientModel>> getAllClients() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ClientModel.fromMap(data);
      })
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب العملاء: ${e.toString()}');
    }
  }

  static Future<List<ClientModel>> searchClients(String userId, String searchTerm, {bool isAdmin = false}) async {
    try {
      List<ClientModel> allClients;

      if (isAdmin) {
        allClients = await getAllClients();
      } else {
        allClients = await getClientsByUser(userId);
      }

      if (searchTerm.isEmpty) {
        return allClients;
      }

      return allClients.where((client) {
        final name = client.clientName.toLowerCase();
        final phone = client.clientPhone;
        final secondPhone = client.secondPhone ?? '';
        final searchLower = searchTerm.toLowerCase();

        return name.contains(searchLower) ||
            phone.contains(searchTerm) ||
            secondPhone.contains(searchTerm);
      }).toList();
    } catch (e) {
      throw Exception('خطأ في البحث: ${e.toString()}');
    }
  }

  static Future<void> updateClientStatus(String clientId, ClientStatus status) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'hasExited': status == ClientStatus.white,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العميل: ${e.toString()}');
    }
  }

  static Future<void> updateClientWithStatus(
      String clientId,
      ClientStatus status,
      int daysRemaining
      ) async {
    try {
      await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .update({
        'status': status.toString().split('.').last,
        'daysRemaining': daysRemaining,
        'hasExited': status == ClientStatus.white,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العميل: ${e.toString()}');
    }
  }

  static Future<void> deleteClient(String clientId) async {
    try {
      // Get client data to delete associated images
      final clientDoc = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .get();

      if (clientDoc.exists) {
        final clientData = clientDoc.data()!;
        final imageUrls = List<String>.from(clientData['imageUrls'] ?? []);

        // Delete images from storage
        for (String imageUrl in imageUrls) {
          try {
            await ImageService.deleteImage(imageUrl);
          } catch (e) {
            print('Error deleting image: $e');
          }
        }
      }

      await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .delete();
    } catch (e) {
      throw Exception('خطأ في حذف العميل: ${e.toString()}');
    }
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      throw Exception('خطأ في حفظ المستخدم: ${e.toString()}');
    }
  }

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', whereIn: ['user', 'agency'])
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      })
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: ${e.toString()}');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('خطأ في حذف المستخدم: ${e.toString()}');
    }
  }

  static Future<void> freezeUser(String userId, String reason) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'isFrozen': true,
        'freezeReason': reason,
      });
    } catch (e) {
      throw Exception('خطأ في تجميد المستخدم: ${e.toString()}');
    }
  }

  static Future<void> unfreezeUser(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'isFrozen': false,
        'freezeReason': null,
      });
    } catch (e) {
      throw Exception('خطأ في إلغاء تجميد المستخدم: ${e.toString()}');
    }
  }

  static Future<void> setUserValidation(String userId, DateTime endDate) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'validationEndDate': endDate.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('خطأ في تحديث صلاحية المستخدم: ${e.toString()}');
    }
  }

  // Notification operations
  static Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('خطأ في حفظ الإشعار: ${e.toString()}');
    }
  }

  static Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      })
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب الإشعارات: ${e.toString()}');
    }
  }

  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      })
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب الإشعارات: ${e.toString()}');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('خطأ في تحديث الإشعار: ${e.toString()}');
    }
  }

  // Settings operations
  static Future<void> saveAdminSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection(FirebaseConstants.adminSettingsCollection)
          .doc('config')
          .set(settings);
    } catch (e) {
      throw Exception('خطأ في حفظ الإعدادات: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.adminSettingsCollection)
          .doc('config')
          .get();

      if (doc.exists) {
        return doc.data()!;
      }
      return _getDefaultAdminSettings();
    } catch (e) {
      return _getDefaultAdminSettings();
    }
  }

  static Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection(FirebaseConstants.userSettingsCollection)
          .doc(userId)
          .set(settings);
    } catch (e) {
      throw Exception('خطأ في حفظ إعدادات المستخدم: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.userSettingsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()!;
      }
      return _getDefaultUserSettings();
    } catch (e) {
      return _getDefaultUserSettings();
    }
  }

  static Map<String, dynamic> _getDefaultAdminSettings() {
    return {
      'clientStatusSettings': {
        'greenDays': 30,
        'yellowDays': 30,
        'redDays': 1,
      },
      'clientNotificationSettings': {
        'firstTier': {'days': 10, 'frequency': 2, 'message': 'تنبيه: تنتهي تأشيرة العميل {clientName} خلال 10 أيام'},
        'secondTier': {'days': 5, 'frequency': 4, 'message': 'تحذير: تنتهي تأشيرة العميل {clientName} خلال 5 أيام'},
        'thirdTier': {'days': 2, 'frequency': 8, 'message': 'عاجل: تنتهي تأشيرة العميل {clientName} خلال يومين'},
      },
      'userNotificationSettings': {
        'firstTier': {'days': 10, 'frequency': 1, 'message': 'تنبيه: ينتهي حسابك خلال 10 أيام'},
        'secondTier': {'days': 5, 'frequency': 1, 'message': 'تحذير: ينتهي حسابك خلال 5 أيام'},
        'thirdTier': {'days': 2, 'frequency': 1, 'message': 'عاجل: ينتهي حسابك خلال يومين'},
      },
      'whatsappMessages': {
        'clientMessage': 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.',
        'userMessage': 'تنبيه: ينتهي حسابك قريباً. يرجى التجديد.',
      },
    };
  }

  static Map<String, dynamic> _getDefaultUserSettings() {
    return {
      'clientStatusSettings': {
        'greenDays': 30,
        'yellowDays': 30,
        'redDays': 1,
      },
      'notificationSettings': {
        'firstTier': {'days': 10, 'frequency': 2, 'message': 'تنبيه: تنتهي تأشيرة العميل {clientName} خلال 10 أيام'},
        'secondTier': {'days': 5, 'frequency': 4, 'message': 'تحذير: تنتهي تأشيرة العميل {clientName} خلال 5 أيام'},
        'thirdTier': {'days': 2, 'frequency': 8, 'message': 'عاجل: تنتهي تأشيرة العميل {clientName} خلال يومين'},
      },
      'whatsappMessage': 'عزيزي العميل {clientName}، تنتهي صلاحية تأشيرتك قريباً. يرجى التواصل معنا.',
      'profile': {
        'notifications': true,
        'whatsapp': true,
        'autoSchedule': true,
      },
    };
  }
}

// services/image_service.dart
class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<List<String>> uploadImages(List<File> imageFiles, String clientId) async {
    List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final compressedFile = await _compressImage(imageFiles[i]);
        final fileName = '${clientId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage
            .ref()
            .child(FirebaseConstants.imagesStorage)
            .child(fileName);

        final uploadTask = ref.putFile(compressedFile);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);

        // Delete temporary compressed file
        try {
          await compressedFile.delete();
        } catch (e) {
          // Ignore delete error for compressed file
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }

    return urls;
  }

  // FIXED: Properly handle the return type from FlutterImageCompress
  static Future<File> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.parent.path}/compressed_${file.path.split('/').last}',
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      // Handle the result properly based on its actual type
      if (result != null && result is XFile) {
        return File(result.path);
      } else if (result != null) {
        // Try to cast to File if it's already a File
        return result as File;
      } else {
        return file; // Return original if compression failed
      }
    } catch (e) {
      return file; // Return original if compression fails
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}

// services/whatsapp_service.dart
class WhatsAppService {
  static Future<void> sendClientMessage({
    required String phoneNumber,
    required PhoneCountry country,
    required String message,
    required String clientName,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber, country);
      final formattedMessage = MessageTemplates.formatMessage(message, {
        'clientName': clientName,
      });

      final encodedMessage = Uri.encodeComponent(formattedMessage);
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      throw Exception('خطأ في فتح الواتساب: ${e.toString()}');
    }
  }

  static Future<void> sendUserMessage({
    required String phoneNumber,
    required String message,
    required String userName,
  }) async {
    try {
      final formattedMessage = MessageTemplates.formatMessage(message, {
        'userName': userName,
      });

      final encodedMessage = Uri.encodeComponent(formattedMessage);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      throw Exception('خطأ في فتح الواتساب: ${e.toString()}');
    }
  }

  static Future<void> callClient({
    required String phoneNumber,
    required PhoneCountry country,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber, country);
      final telUrl = 'tel:+$formattedPhone';

      final uri = Uri.parse(telUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not make call');
      }
    } catch (e) {
      throw Exception('خطأ في المكالمة: ${e.toString()}');
    }
  }

  static String _formatPhoneNumber(String phone, PhoneCountry country) {
    // Remove all non-digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    switch (country) {
      case PhoneCountry.saudi:
      // Remove existing country code
        if (cleaned.startsWith('966')) {
          cleaned = cleaned.substring(3);
        }
        // Remove leading zero
        if (cleaned.startsWith('0')) {
          cleaned = cleaned.substring(1);
        }
        return '966$cleaned';
      case PhoneCountry.yemen:
      // Remove existing country code
        if (cleaned.startsWith('967')) {
          cleaned = cleaned.substring(3);
        }
        // Remove leading zero
        if (cleaned.startsWith('0')) {
          cleaned = cleaned.substring(1);
        }
        return '967$cleaned';
    }
  }
}

// services/notification_service.dart
class NotificationService {
  static Future<void> initialize() async {
    // Initialize local notifications if needed
    print('Notification service initialized');
  }

  static Future<void> scheduleClientNotification({
    required String clientId,
    required String clientName,
    required String message,
    required DateTime scheduledTime,
  }) async {
    // Implementation for scheduling local notifications
    print('Scheduled notification for client: $clientName at $scheduledTime');
  }

  static Future<void> sendUserValidationNotification({
    required String userId,
    required String message,
  }) async {
    // Implementation for sending user validation notifications
    print('Sent validation notification to user: $userId');
  }
}

// services/background_service.dart
class BackgroundService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void startBackgroundTasks() {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(Duration(hours: 1), (timer) {
      _runBackgroundTasks();
    });
  }

  static void stopBackgroundTasks() {
    _timer?.cancel();
    _isRunning = false;
  }

  static Future<void> _runBackgroundTasks() async {
    try {
      await _checkClientNotifications();
      await _checkUserValidations();
      await _autoFreezeExpiredUsers();
    } catch (e) {
      print('Background task error: $e');
    }
  }

  static Future<void> _checkClientNotifications() async {
    try {
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();

      for (final client in clients) {
        if (!client.hasExited) {
          await _scheduleClientNotifications(client, settings);
        }
      }
    } catch (e) {
      print('Client notification check error: $e');
    }
  }

  static Future<void> _scheduleClientNotifications(ClientModel client, Map<String, dynamic> settings) async {
    final clientSettings = settings['clientNotificationSettings'];
    final tiers = [
      clientSettings['firstTier'],
      clientSettings['secondTier'],
      clientSettings['thirdTier'],
    ];

    for (final tier in tiers) {
      final days = tier['days'] as int;
      final frequency = tier['frequency'] as int;
      final message = tier['message'] as String;

      if (client.daysRemaining <= days && client.daysRemaining > 0) {
        // Create notification record
        final notification = NotificationModel(
          id: '${client.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.clientExpiring,
          title: 'تنبيه انتهاء تأشيرة',
          message: MessageTemplates.formatMessage(message, {
            'clientName': client.clientName,
            'daysRemaining': client.daysRemaining.toString(),
          }),
          targetUserId: client.createdBy,
          clientId: client.id,
          priority: _getPriorityFromDays(client.daysRemaining),
          createdAt: DateTime.now(),
        );

        await DatabaseService.saveNotification(notification);
        break; // Only schedule for the most relevant tier
      }
    }
  }

  static Future<void> _checkUserValidations() async {
    try {
      final users = await DatabaseService.getAllUsers();
      final settings = await DatabaseService.getAdminSettings();

      for (final user in users) {
        if (user.validationEndDate != null && !user.isFrozen) {
          await _scheduleUserNotifications(user, settings);
        }
      }
    } catch (e) {
      print('User validation check error: $e');
    }
  }

  static Future<void> _scheduleUserNotifications(UserModel user, Map<String, dynamic> settings) async {
    final daysRemaining = user.validationEndDate!.difference(DateTime.now()).inDays;
    final userSettings = settings['userNotificationSettings'];
    final tiers = [
      userSettings['firstTier'],
      userSettings['secondTier'],
      userSettings['thirdTier'],
    ];

    for (final tier in tiers) {
      final days = tier['days'] as int;
      final message = tier['message'] as String;

      if (daysRemaining <= days && daysRemaining > 0) {
        // Create notification record
        final notification = NotificationModel(
          id: '${user.id}_validation_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.userValidationExpiring,
          title: 'تنبيه انتهاء صلاحية الحساب',
          message: MessageTemplates.formatMessage(message, {
            'userName': user.name,
            'daysRemaining': daysRemaining.toString(),
          }),
          targetUserId: user.id,
          priority: _getPriorityFromDays(daysRemaining),
          createdAt: DateTime.now(),
        );

        await DatabaseService.saveNotification(notification);
        break; // Only schedule for the most relevant tier
      }
    }
  }

  static Future<void> _autoFreezeExpiredUsers() async {
    try {
      final users = await DatabaseService.getAllUsers();

      for (final user in users) {
        if (user.validationEndDate != null &&
            user.validationEndDate!.isBefore(DateTime.now()) &&
            !user.isFrozen) {
          await DatabaseService.freezeUser(user.id, 'انتهت صلاحية الحساب تلقائياً');
        }
      }
    } catch (e) {
      print('Auto-freeze error: $e');
    }
  }

  static NotificationPriority _getPriorityFromDays(int days) {
    if (days <= 2) return NotificationPriority.high;
    if (days <= 5) return NotificationPriority.medium;
    return NotificationPriority.low;
  }
}

// services/status_update_service.dart
class StatusUpdateService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void startAutoStatusUpdate() {
    if (_isRunning) return;

    _isRunning = true;
    print('🔄 Starting auto status update service...');

    // Run immediately once
    _updateAllClientStatuses();

    // Then run every 6 hours
    _timer = Timer.periodic(Duration(hours: 6), (timer) {
      _updateAllClientStatuses();
    });
  }

  static void stopAutoStatusUpdate() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('⏹️ Auto status update service stopped');
  }

  static Future<void> _updateAllClientStatuses() async {
    try {
      print('🔄 Running auto status update...');

      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();

      final statusSettings = settings['clientStatusSettings'] ?? {};
      final greenDays = statusSettings['greenDays'] ?? 30;
      final yellowDays = statusSettings['yellowDays'] ?? 30;
      final redDays = statusSettings['redDays'] ?? 1;

      int updatedCount = 0;

      for (final client in clients) {
        if (!client.hasExited) {
          final currentDaysRemaining = StatusCalculator.calculateDaysRemaining(client.entryDate);
          final newStatus = StatusCalculator.calculateStatus(
            client.entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          );

          // Update if status changed or days remaining changed significantly
          if (newStatus != client.status ||
              (currentDaysRemaining - client.daysRemaining).abs() > 0) {

            await DatabaseService.updateClientWithStatus(
                client.id,
                newStatus,
                currentDaysRemaining
            );
            updatedCount++;
          }
        }
      }

      print('✅ Auto status update completed. Updated $updatedCount clients.');

    } catch (e) {
      print('❌ Auto status update error: $e');
    }
  }

  static Future<void> forceUpdateAllStatuses() async {
    print('🔄 Force updating all client statuses...');
    await _updateAllClientStatuses();
  }
}