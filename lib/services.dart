import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'models.dart';
import 'core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: 'استخدم بصمتك لتسجيل الدخول',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<void> enableBiometric(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_$userId', true);
  }

  static Future<void> disableBiometric(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_$userId', false);
  }

  static Future<bool> isBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled_$userId') ?? false;
  }
}

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserModel> login(String username, String password, {bool useBiometric = false}) async {
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

  static Future<UserModel?> loginWithBiometric(String username) async {
    try {
      if (await BiometricService.authenticateWithBiometrics()) {
        final credentials = await getSavedCredentials();
        if (credentials['username'] == username && credentials['password'] != null) {
          return await login(username, credentials['password']!, useBiometric: true);
        }
      }
      return null;
    } catch (e) {
      return null;
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

  static Future<void> createDefaultAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final adminUser = UserModel(
          id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
          username: 'admin',
          password: _hashPassword('admin123'),
          role: UserRole.admin,
          name: 'مدير النظام',
          phone: '966500000000',
          email: 'admin@example.com',
          isActive: true,
          isFrozen: false,
          validationEndDate: DateTime.now().add(Duration(days: 365 * 10)),
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
      } else {
        print('👤 Admin user already exists');
      }
    } catch (e) {
      print('❌ Error creating admin user: $e');
    }
  }
}

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Delegate to ImageServiceExtensions for image picking
  static Future<List<File>?> pickMultipleImages({
    int maxImages = 10,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) => ImageServiceExtensions.pickMultipleImages(
    maxImages: maxImages,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  static Future<File?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) => ImageServiceExtensions.pickSingleImage(
    source: source,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  static Future<File?> pickImageWithSourceDialog(BuildContext context) =>
      ImageServiceExtensions.pickImageWithSourceDialog(context);

  // Core Firebase Storage operations
  static Future<List<String>> uploadImages(List<File> imageFiles, String clientId) async {
    List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final compressedFile = await _compressImage(imageFiles[i]);
        final fileName = '${clientId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage
            .ref()
            .child(FirebaseConstants.imagesStorage)
            .child(clientId)
            .child(fileName);

        final uploadTask = ref.putFile(compressedFile);
        final snapshot = await uploadTask;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);

        try {
          await compressedFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      } catch (e) {
        throw Exception('خطأ في رفع الصورة: ${e.toString()}');
      }
    }

    return urls;
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('خطأ في حذف الصورة: ${e.toString()}');
    }
  }

  static Future<void> downloadImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('لا يمكن فتح الصورة');
      }
    } catch (e) {
      throw Exception('خطأ في تحميل الصورة: ${e.toString()}');
    }
  }

  static Future<void> openImageInBrowser(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('لا يمكن فتح الصورة في المتصفح');
      }
    } catch (e) {
      throw Exception('خطأ في فتح الصورة: ${e.toString()}');
    }
  }

  // Image compression helper
  static Future<File> _compressImage(File file) async {
    try {
      final String targetPath = '${file.parent.path}/compressed_${file.uri.pathSegments.last}';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result != null) {
        return File(result.path);
      } else {
        return file;
      }
    } catch (e) {
      return file;
    }
  }

  // Batch operations for client management
  static Future<void> deleteClientImages(List<String> imageUrls) async {
    for (String imageUrl in imageUrls) {
      try {
        await deleteImage(imageUrl);
      } catch (e) {
        // Continue deleting other images even if one fails
        print('Failed to delete image: $imageUrl, Error: $e');
      }
    }
  }

  // Utility method for getting image file size
  static Future<int> getImageFileSize(File imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      throw Exception('خطأ في حساب حجم الصورة: ${e.toString()}');
    }
  }

  // Validate image before upload
  static Future<bool> validateImage(File imageFile, {int maxSizeInMB = 10}) async {
    try {
      final fileSize = await getImageFileSize(imageFile);
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;

      return fileSize <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }
}

class ImageServiceExtensions {
  static final ImagePicker _picker = ImagePicker();

  /// Picks multiple images from gallery or camera
  /// Returns null if user cancels or empty list if no images selected
  static Future<List<File>?> pickMultipleImages({
    int maxImages = 10,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Request permissions first
      final permission = await _requestGalleryPermission();
      if (!permission) {
        throw Exception('صلاحية الوصول للمعرض مطلوبة');
      }

      // Pick multiple images
      final List<XFile>? xFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (xFiles == null || xFiles.isEmpty) {
        return null;
      }

      // Limit number of images if specified
      final limitedFiles = xFiles.take(maxImages).toList();

      // Convert XFile to File
      final List<File> files = limitedFiles.map((xFile) => File(xFile.path)).toList();

      return files;
    } catch (e) {
      throw Exception('خطأ في اختيار الصور: ${e.toString()}');
    }
  }

  /// Picks a single image with option to choose source
  static Future<File?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Request appropriate permissions
      bool permission;
      if (source == ImageSource.camera) {
        permission = await _requestCameraPermission();
      } else {
        permission = await _requestGalleryPermission();
      }

      if (!permission) {
        throw Exception('الصلاحية المطلوبة غير متاحة');
      }

      final XFile? xFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (xFile == null) {
        return null;
      }

      return File(xFile.path);
    } catch (e) {
      throw Exception('خطأ في اختيار الصورة: ${e.toString()}');
    }
  }

  /// Shows image source selection dialog and picks image
  static Future<File?> pickImageWithSourceDialog(BuildContext context) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('الكاميرا'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      return await pickSingleImage(source: source);
    }
    return null;
  }

  /// Downloads and saves image from URL to device
  static Future<String> downloadAndSaveImage(String imageUrl, String fileName) async {
    try {
      final permission = await _requestStoragePermission();
      if (!permission) {
        throw Exception('صلاحية التخزين مطلوبة');
      }

      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, 'downloads', fileName);

      // Create directory if it doesn't exist
      final downloadDir = Directory(path.dirname(filePath));
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }

      // Download the image
      await dio.download(imageUrl, filePath);

      return filePath;
    } catch (e) {
      throw Exception('خطأ في تحميل الصورة: ${e.toString()}');
    }
  }

  /// Requests gallery/photos permission
  static Future<bool> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status == PermissionStatus.granted;
  }

  /// Requests camera permission
  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  /// Requests storage permission
  static Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }
}

// New CommunicationService class
class CommunicationService {
  /// Sends WhatsApp message to a phone number
  static Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      if (message.isEmpty) {
        throw Exception('نص الرسالة مطلوب');
      }

      // Clean and format phone number
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Ensure phone number has country code
      if (!cleanedPhone.startsWith('966') && !cleanedPhone.startsWith('967')) {
        // Default to Saudi Arabia if no country code
        if (cleanedPhone.startsWith('5')) {
          cleanedPhone = '966$cleanedPhone';
        } else if (cleanedPhone.startsWith('7')) {
          cleanedPhone = '967$cleanedPhone';
        } else {
          throw Exception('رقم الهاتف غير صحيح');
        }
      }

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$cleanedPhone?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('تطبيق الواتساب غير مثبت');
      }
    } catch (e) {
      throw Exception('خطأ في إرسال رسالة الواتساب: ${e.toString()}');
    }
  }

  /// Makes a phone call to the specified number
  static Future<void> makePhoneCall(String phoneNumber) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      // Clean phone number
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Add + if not present and starts with country code
      if (!cleanedPhone.startsWith('+') && (cleanedPhone.startsWith('966') || cleanedPhone.startsWith('967'))) {
        cleanedPhone = '+$cleanedPhone';
      }

      final telUrl = 'tel:$cleanedPhone';
      final uri = Uri.parse(telUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('لا يمكن إجراء المكالمة');
      }
    } catch (e) {
      throw Exception('خطأ في إجراء المكالمة: ${e.toString()}');
    }
  }

  /// Sends SMS to the specified number
  static Future<void> sendSMS(String phoneNumber, String message) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      if (message.isEmpty) {
        throw Exception('نص الرسالة مطلوب');
      }

      // Clean phone number
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);
      final smsUrl = 'sms:$cleanedPhone?body=$encodedMessage';
      final uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('لا يمكن إرسال الرسالة النصية');
      }
    } catch (e) {
      throw Exception('خطأ في إرسال الرسالة النصية: ${e.toString()}');
    }
  }

  /// Opens email app with pre-filled recipient and subject
  static Future<void> sendEmail(String email, {String? subject, String? body}) async {
    try {
      if (email.isEmpty) {
        throw Exception('عنوان البريد الإلكتروني مطلوب');
      }

      String emailUrl = 'mailto:$email';

      final params = <String>[];
      if (subject != null && subject.isNotEmpty) {
        params.add('subject=${Uri.encodeComponent(subject)}');
      }
      if (body != null && body.isNotEmpty) {
        params.add('body=${Uri.encodeComponent(body)}');
      }

      if (params.isNotEmpty) {
        emailUrl += '?${params.join('&')}';
      }

      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('لا يمكن فتح تطبيق البريد الإلكتروني');
      }
    } catch (e) {
      throw Exception('خطأ في إرسال البريد الإلكتروني: ${e.toString()}');
    }
  }
}

// Enhanced FileService for file operations
class FileService {
  /// Picks files with specified extensions
  static Future<List<File>?> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      return files;
    } catch (e) {
      throw Exception('خطأ في اختيار الملفات: ${e.toString()}');
    }
  }

  /// Saves data to a file in the app's documents directory
  static Future<String> saveDataToFile(String fileName, String data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, fileName));

      await file.writeAsString(data);

      return file.path;
    } catch (e) {
      throw Exception('خطأ في حفظ الملف: ${e.toString()}');
    }
  }

  /// Reads data from a file
  static Future<String> readDataFromFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        throw Exception('الملف غير موجود');
      }

      return await file.readAsString();
    } catch (e) {
      throw Exception('خطأ في قراءة الملف: ${e.toString()}');
    }
  }

  /// Deletes a file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('خطأ في حذف الملف: ${e.toString()}');
    }
  }

  /// Gets the size of a file in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        throw Exception('الملف غير موجود');
      }

      return await file.length();
    } catch (e) {
      throw Exception('خطأ في حساب حجم الملف: ${e.toString()}');
    }
  }
}

// Addition to ClientModel class - missing getter method
extension ClientModelExtensions on ClientModel {
  /// Returns the full client phone number with country code
  String get fullClientPhone => fullPrimaryPhone;

  /// Returns both phone numbers formatted
  List<String> get allPhoneNumbers {
    final phones = <String>[fullPrimaryPhone];
    if (secondPhone != null && secondPhone!.isNotEmpty) {
      phones.add(fullSecondaryPhone);
    }
    return phones;
  }

  /// Returns the primary phone number for display
  String get displayPhoneNumber {
    return WhatsAppService.getDisplayPhoneNumber(clientPhone, phoneCountry);
  }

  /// Returns the secondary phone number for display
  String? get displaySecondaryPhoneNumber {
    if (secondPhone == null || secondPhone!.isEmpty) return null;
    return WhatsAppService.getDisplayPhoneNumber(secondPhone!, phoneCountry);
  }
}

// Enhanced validation service
class ValidationService {
  /// Validates multiple phone numbers
  static List<String> validatePhoneNumbers(List<String> phoneNumbers, PhoneCountry country) {
    final errors = <String>[];

    for (int i = 0; i < phoneNumbers.length; i++) {
      try {
        final isValid = WhatsAppService.isValidPhoneNumber(phoneNumbers[i], country);
        if (!isValid) {
          errors.add('رقم الهاتف ${i + 1} غير صحيح');
        }
      } catch (e) {
        errors.add('رقم الهاتف ${i + 1}: ${e.toString()}');
      }
    }

    return errors;
  }

  /// Validates client data comprehensively
  static List<String> validateClientData(ClientModel client) {
    final errors = <String>[];

    // Validate required fields
    if (client.clientName.trim().isEmpty) {
      errors.add('اسم العميل مطلوب');
    }

    if (client.clientPhone.trim().isEmpty) {
      errors.add('رقم الهاتف الأساسي مطلوب');
    }

    // Validate phone numbers
    try {
      final isValid = WhatsAppService.isValidPhoneNumber(client.clientPhone, client.phoneCountry);
      if (!isValid) {
        errors.add('رقم الهاتف الأساسي غير صحيح');
      }
    } catch (e) {
      errors.add('رقم الهاتف الأساسي: ${e.toString()}');
    }

    // Validate secondary phone if provided
    if (client.secondPhone != null && client.secondPhone!.isNotEmpty) {
      try {
        final isValid = WhatsAppService.isValidPhoneNumber(client.secondPhone!, client.phoneCountry);
        if (!isValid) {
          errors.add('رقم الهاتف الثانوي غير صحيح');
        }
      } catch (e) {
        errors.add('رقم الهاتف الثانوي: ${e.toString()}');
      }
    }

    // Validate entry date
    if (client.entryDate.isAfter(DateTime.now())) {
      errors.add('تاريخ الدخول لا يمكن أن يكون في المستقبل');
    }

    return errors;
  }

  /// Validates user data
  static List<String> validateUserData(UserModel user) {
    final errors = <String>[];

    // Validate required fields
    if (user.username.trim().isEmpty) {
      errors.add('اسم المستخدم مطلوب');
    }

    if (user.name.trim().isEmpty) {
      errors.add('الاسم الكامل مطلوب');
    }

    if (user.phone.trim().isEmpty) {
      errors.add('رقم الهاتف مطلوب');
    }

    // Validate username format
    if (!RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(user.username)) {
      errors.add('اسم المستخدم يجب أن يكون 3 أحرف على الأقل ويحتوي على أحرف وأرقام فقط');
    }

    // Validate email if provided
    if (user.email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(user.email)) {
      errors.add('البريد الإلكتروني غير صحيح');
    }

    return errors;
  }
}
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> clearCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  static Future<void> saveClient(ClientModel client, List<File>? images) async {
    try {
      List<String> imageUrls = [];

      if (images != null && images.isNotEmpty) {
        imageUrls = await ImageService.uploadImages(images, client.id);
      }

      final updatedClient = client.copyWith(
        imageUrls: [...client.imageUrls, ...imageUrls],
        updatedAt: DateTime.now(),
        version: client.version + 1,              // Increment version on update
      );

      final docRef = _firestore.collection(FirebaseConstants.clientsCollection).doc(client.id);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          final currentVersion = doc.data()?['version'] ?? 1;
          if (currentVersion != client.version) {
            throw Exception('البيانات تم تعديلها من مستخدم آخر. يرجى إعادة التحميل والمحاولة مرة أخرى.');
          }
        }

        transaction.set(docRef, updatedClient.toMap());
      });

      await clearCache();
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

  static Future<List<ClientModel>> getFilteredClients({
    String? userId,
    bool isAdmin = false,
    String? filterByUser,
    ClientStatus? filterByStatus,
    VisaType? filterByVisaType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<ClientModel> clients;
      
      if (isAdmin) {
        clients = await getAllClients();
      } else {
        clients = await getClientsByUser(userId!);
      }

      if (filterByUser != null && filterByUser.isNotEmpty) {
        clients = clients.where((c) => c.createdBy == filterByUser).toList();
      }

      if (filterByStatus != null) {
        clients = clients.where((c) => c.status == filterByStatus).toList();
      }

      if (filterByVisaType != null) {
        clients = clients.where((c) => c.visaType == filterByVisaType).toList();
      }

      if (startDate != null) {
        clients = clients.where((c) => c.entryDate.isAfter(startDate.subtract(Duration(days: 1)))).toList();
      }

      if (endDate != null) {
        clients = clients.where((c) => c.entryDate.isBefore(endDate.add(Duration(days: 1)))).toList();
      }

      return clients;
    } catch (e) {
      throw Exception('خطأ في تصفية العملاء: ${e.toString()}');
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

      await clearCache();
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

      await clearCache();
    } catch (e) {
      throw Exception('خطأ في تحديث حالة العميل: ${e.toString()}');
    }
  }

  static Future<void> deleteClient(String clientId) async {
    try {
      final clientDoc = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .doc(clientId)
          .get();

      if (clientDoc.exists) {
        final clientData = clientDoc.data()!;
        final imageUrls = List<String>.from(clientData['imageUrls'] ?? []);

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

      await clearCache();
    } catch (e) {
      throw Exception('خطأ في حذف العميل: ${e.toString()}');
    }
  }

  static Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.id)
          .set(user.toMap());

      await clearCache();
    } catch (e) {
      throw Exception('خطأ في حفظ المستخدم: ${e.toString()}');
    }
  }

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .where((doc) => doc.data()['role'] != 'admin')
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

  static Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final clientsQuery = await _firestore
          .collection(FirebaseConstants.clientsCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      for (var doc in clientsQuery.docs) {
        await deleteClient(doc.id);
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .delete();

      await clearCache();
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

      await clearCache();
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

      await clearCache();
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

      await clearCache();
    } catch (e) {
      throw Exception('خطأ في تحديث صلاحية المستخدم: ${e.toString()}');
    }
  }

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

  static Future<void> saveAdminSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection(FirebaseConstants.adminSettingsCollection)
          .doc('config')
          .set(settings);

      await clearCache();
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

      await clearCache();
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
      'adminFilters': {
        'showOnlyMyClients': false,
        'showOnlyMyNotifications': false,
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
        'biometric': false,
      },
    };
  }
}

class WhatsAppService {
  // Constants for phone number validation
  static const Map<PhoneCountry, PhoneNumberRules> _phoneRules = {
    PhoneCountry.saudi: PhoneNumberRules(
      countryCode: '966',
      validPrefixes: ['5'],
      minLength: 9,
      maxLength: 9,
      displayName: 'السعودية',
    ),
    PhoneCountry.yemen: PhoneNumberRules(
      countryCode: '967',
      validPrefixes: ['7'],
      minLength: 9,
      maxLength: 9,
      displayName: 'اليمن',
    ),
  };

  static Future<void> sendClientMessage({
    required String phoneNumber,
    required PhoneCountry country,
    required String message,
    required String clientName,
  }) async {
    try {
      // Validate input parameters
      _validateInputs(phoneNumber: phoneNumber, message: message);

      // Format and validate phone number
      final formattedPhone = _formatPhoneNumber(phoneNumber, country);

      // Format message with client name
      final formattedMessage = MessageTemplates.formatMessage(message, {
        'clientName': clientName,
      });

      // Launch WhatsApp
      await _launchWhatsApp(formattedPhone, formattedMessage);

    } catch (e) {
      throw _createWhatsAppException(e);
    }
  }

  static Future<void> sendUserMessage({
    required String phoneNumber,
    required String message,
    required String userName,
    PhoneCountry country = PhoneCountry.saudi, // Default country for user messages
  }) async {
    try {
      // Validate input parameters
      _validateInputs(phoneNumber: phoneNumber, message: message);

      // Format phone number with country code if needed
      final formattedPhone = phoneNumber.startsWith('+') || phoneNumber.startsWith('966') || phoneNumber.startsWith('967')
          ? _formatInternationalNumber(phoneNumber)
          : _formatPhoneNumber(phoneNumber, country);

      // Format message with user name
      final formattedMessage = MessageTemplates.formatMessage(message, {
        'userName': userName,
      });

      // Launch WhatsApp
      await _launchWhatsApp(formattedPhone, formattedMessage);

    } catch (e) {
      throw _createWhatsAppException(e);
    }
  }

  static Future<void> callClient({
    required String phoneNumber,
    required PhoneCountry country,
  }) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      // Format and validate phone number
      final formattedPhone = _formatPhoneNumber(phoneNumber, country);

      // Launch phone dialer
      await _makePhoneCall(formattedPhone);

    } catch (e) {
      throw _createCallException(e);
    }
  }

  /// Validates common input parameters
  static void _validateInputs({String? phoneNumber, String? message}) {
    if (phoneNumber != null && phoneNumber.trim().isEmpty) {
      throw Exception('رقم الهاتف مطلوب');
    }

    if (message != null && message.trim().isEmpty) {
      throw Exception('نص الرسالة مطلوب');
    }
  }

  /// Formats phone number according to country rules with comprehensive validation
  static String _formatPhoneNumber(String phone, PhoneCountry country) {
    if (phone.isEmpty) {
      throw Exception('رقم الهاتف فارغ');
    }

    // Get phone rules for the country
    final rules = _phoneRules[country];
    if (rules == null) {
      throw Exception('دولة غير مدعومة');
    }

    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      throw Exception('رقم الهاتف يجب أن يحتوي على أرقام');
    }

    // Remove country code if present
    if (cleaned.startsWith(rules.countryCode)) {
      cleaned = cleaned.substring(rules.countryCode.length);
    }

    // Remove leading zero if present
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Validate phone number length
    if (cleaned.length < rules.minLength || cleaned.length > rules.maxLength) {
      throw Exception(
          'رقم هاتف ${rules.displayName} يجب أن يكون ${rules.minLength} أرقام'
      );
    }

    // Validate phone number prefix
    final hasValidPrefix = rules.validPrefixes.any((prefix) => cleaned.startsWith(prefix));
    if (!hasValidPrefix) {
      final prefixList = rules.validPrefixes.join(' أو ');
      throw Exception(
          'رقم هاتف ${rules.displayName} يجب أن يبدأ بـ $prefixList'
      );
    }

    // Return formatted international number
    return '${rules.countryCode}$cleaned';
  }

  /// Formats international phone numbers that already include country codes
  static String _formatInternationalNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle numbers that start with + or country codes
    if (phoneNumber.startsWith('+')) {
      cleaned = phoneNumber.substring(1).replaceAll(RegExp(r'[^\d]'), '');
    }

    // Validate that it's a supported country code
    if (cleaned.startsWith('966') || cleaned.startsWith('967')) {
      return cleaned;
    }

    throw Exception('رقم الهاتف الدولي غير مدعوم');
  }

  /// Launches WhatsApp with formatted phone number and message
  static Future<void> _launchWhatsApp(String formattedPhone, String message) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('تطبيق الواتساب غير مثبت على الجهاز');
      }
    } catch (e) {
      if (e.toString().contains('تطبيق الواتساب')) {
        rethrow;
      }
      throw Exception('فشل في فتح تطبيق الواتساب');
    }
  }

  /// Makes a phone call using the device's dialer
  static Future<void> _makePhoneCall(String formattedPhone) async {
    try {
      final telUrl = 'tel:+$formattedPhone';
      final uri = Uri.parse(telUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('لا يمكن الوصول إلى تطبيق الهاتف');
      }
    } catch (e) {
      if (e.toString().contains('لا يمكن الوصول')) {
        rethrow;
      }
      throw Exception('فشل في إجراء المكالمة');
    }
  }

  /// Creates standardized WhatsApp exception messages
  static Exception _createWhatsAppException(dynamic error) {
    final errorMessage = error.toString();

    if (errorMessage.contains('رقم الهاتف')) {
      return Exception('خطأ في رقم الهاتف: ${error.toString()}');
    } else if (errorMessage.contains('تطبيق الواتساب')) {
      return Exception('خطأ في تطبيق الواتساب: ${error.toString()}');
    } else {
      return Exception('خطأ في إرسال رسالة الواتساب: ${error.toString()}');
    }
  }

  /// Creates standardized call exception messages
  static Exception _createCallException(dynamic error) {
    final errorMessage = error.toString();

    if (errorMessage.contains('رقم الهاتف')) {
      return Exception('خطأ في رقم الهاتف: ${error.toString()}');
    } else if (errorMessage.contains('تطبيق الهاتف')) {
      return Exception('خطأ في تطبيق الهاتف: ${error.toString()}');
    } else {
      return Exception('خطأ في إجراء المكالمة: ${error.toString()}');
    }
  }

  /// Validates phone number format for a specific country
  static bool isValidPhoneNumber(String phoneNumber, PhoneCountry country) {
    try {
      _formatPhoneNumber(phoneNumber, country);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets formatted display number for UI purposes
  static String getDisplayPhoneNumber(String phoneNumber, PhoneCountry country) {
    try {
      final formatted = _formatPhoneNumber(phoneNumber, country);
      final rules = _phoneRules[country]!;

      // Format as +XXX XX XXX XXXX for display
      final countryCode = formatted.substring(0, rules.countryCode.length);
      final localNumber = formatted.substring(rules.countryCode.length);

      return '+$countryCode ${_formatLocalNumberForDisplay(localNumber)}';
    } catch (e) {
      return phoneNumber; // Return original if formatting fails
    }
  }

  /// Formats local phone number for display
  static String _formatLocalNumberForDisplay(String localNumber) {
    if (localNumber.length == 9) {
      // Format as XX XXX XXXX
      return '${localNumber.substring(0, 2)} ${localNumber.substring(2, 5)} ${localNumber.substring(5)}';
    }
    return localNumber;
  }
}

/// Phone number validation rules for different countries
class PhoneNumberRules {
  final String countryCode;
  final List<String> validPrefixes;
  final int minLength;
  final int maxLength;
  final String displayName;

  const PhoneNumberRules({
    required this.countryCode,
    required this.validPrefixes,
    required this.minLength,
    required this.maxLength,
    required this.displayName,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'passenger_channel',
      'Passenger Notifications',
      channelDescription: 'Notifications for passenger visa expiry',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

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
        
        await NotificationService.showNotification(
          id: notification.hashCode,
          title: notification.title,
          body: notification.message,
          payload: notification.id,
        );
        
        break;
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
        break;
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

class StatusUpdateService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void startAutoStatusUpdate() {
    if (_isRunning) return;

    _isRunning = true;
    print('🔄 Starting auto status update service...');

    _updateAllClientStatuses();

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

      await DatabaseService.clearCache();
      print('✅ Auto status update completed. Updated $updatedCount clients.');

    } catch (e) {
      print('❌ Auto status update error: $e');
    }
  }
// Add this method to the StatusUpdateService class in services.dart
  static void startPeriodicUpdates() {
    startAutoStatusUpdate();
  }

  static void stopPeriodicUpdates() {
    stopAutoStatusUpdate();
  }
  static Future<void> forceUpdateAllStatuses() async {
    print('🔄 Force updating all client statuses...');
    await _updateAllClientStatuses();
  }
}