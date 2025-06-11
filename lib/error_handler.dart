import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  static String getArabicErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية للوصول لهذه البيانات';
        case 'unavailable':
          return 'الخدمة غير متاحة حالياً، حاول لاحقاً';
        case 'deadline-exceeded':
          return 'انتهت مهلة الاتصال، حاول مرة أخرى';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً';
        case 'resource-exhausted':
          return 'تم تجاوز الحد المسموح، حاول لاحقاً';
        case 'failed-precondition':
          return 'فشل في تنفيذ العملية، تحقق من البيانات';
        case 'aborted':
          return 'تم إلغاء العملية، حاول مرة أخرى';
        case 'out-of-range':
          return 'القيم المدخلة خارج النطاق المسموح';
        case 'internal':
          return 'خطأ داخلي في الخادم';
        case 'data-loss':
          return 'فقدان في البيانات';
        default:
          return 'حدث خطأ غير متوقع: ${error.message}';
      }
    }

    if (error is Exception) {
      final message = error.toString();
      if (message.contains('network')) {
        return 'خطأ في الشبكة، تحقق من الاتصال';
      }
      if (message.contains('timeout')) {
        return 'انتهت مهلة الاتصال، حاول مرة أخرى';
      }
      if (message.contains('format')) {
        return 'خطأ في تنسيق البيانات';
      }
    }

    return 'حدث خطأ غير متوقع، حاول لاحقاً';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getArabicErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'موافق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, dynamic error, {VoidCallback? onRetry}) {
    final message = getArabicErrorMessage(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: Text('إعادة المحاولة'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    print('❌ Error in $operation: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    
    // Here you can add crash reporting service like Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

// Extension to add error handling to controllers
extension ControllerErrorHandling on ChangeNotifier {
  Future<T?> handleOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? successMessage,
    bool showErrorDialog = false,
  }) async {
    try {
      final result = await operation();
      
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      return result;
    } catch (error, stackTrace) {
      ErrorHandler.logError('Controller operation', error, stackTrace);
      
      if (showErrorDialog) {
        ErrorHandler.showErrorDialog(context, error);
      } else {
        ErrorHandler.showErrorSnackBar(context, error);
      }
      
      return null;
    }
  }
}