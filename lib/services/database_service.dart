import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../core/constants/firebase_constants.dart';
import '../core/utils/status_calculator.dart';
import 'image_service.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Client operations
  static Future<void> saveClient(ClientModel client, File? visaImage, File? passportImage) async {
    try {
      String? visaImageUrl;
      String? passportImageUrl;

      if (visaImage != null) {
        visaImageUrl = await ImageService.uploadCompressedImage(visaImage, 'visa_${client.id}');
      }
      if (passportImage != null) {
        passportImageUrl = await ImageService.uploadCompressedImage(passportImage, 'passport_${client.id}');
      }

      final updatedClient = client.copyWith(
        visaImageUrl: visaImageUrl ?? client.visaImageUrl,
        passportImageUrl: passportImageUrl ?? client.passportImageUrl,
        updatedAt: DateTime.now(),
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
          .map((doc) => ClientModel.fromMap(doc.data()))
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
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب العملاء: ${e.toString()}');
    }
  }

  static Future<void> updateClientStatus(String clientId, ClientStatus status) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'hasExited': status == ClientStatus.white,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // If marking as exited, record exit date
      if (status == ClientStatus.white) {
        updateData['exitDate'] = DateTime.now().millisecondsSinceEpoch;
      }

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
      final updateData = {
        'status': status.toString().split('.').last,
        'daysRemaining': daysRemaining,
        'hasExited': status == ClientStatus.white,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (status == ClientStatus.white) {
        updateData['exitDate'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العميل: ${e.toString()}');
    }
  }

  static Future<List<ClientModel>> getClientsByStatus(ClientStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .where('status', isEqualTo: status.toString().split('.').last)
          .where('hasExited', isEqualTo: false)
          .orderBy('daysRemaining', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب العملاء حسب الحالة: ${e.toString()}');
    }
  }

  static Future<List<ClientModel>> getExpiringClients(int daysThreshold) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .where('daysRemaining', isLessThanOrEqualTo: daysThreshold)
          .where('hasExited', isEqualTo: false)
          .orderBy('daysRemaining', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب العملاء المنتهية التأشيرات: ${e.toString()}');
    }
  }

  static Future<void> deleteClient(String clientId) async {
    try {
      // Get client data first to delete images
      final doc = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .get();
      
      if (doc.exists) {
        final client = ClientModel.fromMap(doc.data()!);
        
        // Delete images if they exist
        if (client.visaImageUrl != null) {
          await ImageService.deleteImage(client.visaImageUrl!);
        }
        if (client.passportImageUrl != null) {
          await ImageService.deleteImage(client.passportImageUrl!);
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

  // Search clients
  static Future<List<ClientModel>> searchClients(String query, String? userId) async {
    try {
      Query queryRef = _firestore.collection(FirebaseConstants.clientsCollection);
      
      // Filter by user if not admin
      if (userId != null) {
        queryRef = queryRef.where('createdBy', isEqualTo: userId);
      }

      final querySnapshot = await queryRef.get();
      
      final allClients = querySnapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter locally for better search
      return allClients.where((client) => client.matchesSearch(query)).toList();
    } catch (e) {
      throw Exception('خطأ في البحث: ${e.toString()}');
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
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: ${e.toString()}');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      // Delete all clients created by this user
      final clientsSnapshot = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final doc in clientsSnapshot.docs) {
        await deleteClient(doc.id);
      }

      // Delete user
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
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
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
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
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