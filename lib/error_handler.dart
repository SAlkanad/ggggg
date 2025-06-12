import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

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
        case 'not-found':
          return 'البيانات المطلوبة غير موجودة';
        case 'already-exists':
          return 'البيانات موجودة مسبقاً';
        case 'invalid-argument':
          return 'بيانات غير صحيحة';
        case 'cancelled':
          return 'تم إلغاء العملية';
        default:
          return 'حدث خطأ غير متوقع: ${error.message}';
      }
    }

    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      if (message.contains('network') || message.contains('internet')) {
        return 'خطأ في الشبكة، تحقق من الاتصال';
      }
      if (message.contains('timeout')) {
        return 'انتهت مهلة الاتصال، حاول مرة أخرى';
      }
      if (message.contains('format') || message.contains('parse')) {
        return 'خطأ في تنسيق البيانات';
      }
      if (message.contains('permission')) {
        return 'ليس لديك صلاحية لتنفيذ هذه العملية';
      }
      if (message.contains('biometric') || message.contains('fingerprint')) {
        return 'خطأ في البصمة، تحقق من إعدادات الجهاز';
      }
      if (message.contains('cache') || message.contains('storage')) {
        return 'خطأ في التخزين المؤقت';
      }
      if (message.contains('image') || message.contains('photo')) {
        return 'خطأ في معالجة الصورة';
      }
      if (message.contains('file')) {
        return 'خطأ في الملف';
      }
      if (message.contains('auth')) {
        return 'خطأ في المصادقة';
      }
    }

    final errorString = error.toString();
    if (errorString.contains('RangeError')) {
      return 'خطأ في النطاق المحدد';
    }
    if (errorString.contains('FormatException')) {
      return 'خطأ في تنسيق البيانات';
    }
    if (errorString.contains('TypeError')) {
      return 'خطأ في نوع البيانات';
    }
    if (errorString.contains('StateError')) {
      return 'خطأ في حالة التطبيق';
    }

    return 'حدث خطأ غير متوقع، حاول لاحقاً';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
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
        duration: duration,
        action: action ?? SnackBarAction(
          label: 'موافق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, dynamic error, {
    VoidCallback? onRetry,
    String? title,
    List<Widget>? additionalActions,
  }) {
    final message = getArabicErrorMessage(error);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(title ?? 'خطأ'),
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
          if (additionalActions != null) ...additionalActions,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
    IconData? icon,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor ?? Colors.blue),
              SizedBox(width: 8),
            ],
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onCancel != null) onCancel();
            },
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmText),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final errorMessage = getArabicErrorMessage(error);
    
    print('❌ [$timestamp] Error in $operation: $errorMessage');
    print('   Original error: $error');
    
    if (stackTrace != null) {
      print('   Stack trace: $stackTrace');
    }
    
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      information: [
        DiagnosticsProperty('operation', operation),
        DiagnosticsProperty('timestamp', timestamp),
        DiagnosticsProperty('arabicMessage', errorMessage),
      ],
    );
  }

  static Future<void> clearApplicationCache() async {
    try {
      CacheManager.clear();
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys().where((key) => 
        key.startsWith('cache_') || 
        key.startsWith('temp_') ||
        key.startsWith('last_sync_')
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      print('✅ Application cache cleared successfully');
    } catch (e) {
      print('❌ Failed to clear application cache: $e');
      throw Exception('فشل في مسح ذاكرة التخزين المؤقت');
    }
  }

  static Future<bool> handleNetworkError(BuildContext context, dynamic error) async {
    final message = getArabicErrorMessage(error);
    
    if (message.contains('شبكة') || message.contains('اتصال')) {
      showErrorDialog(
        context,
        error,
        title: 'خطأ في الشبكة',
        onRetry: () async {
          await clearApplicationCache();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم مسح ذاكرة التخزين المؤقت')),
          );
        },
        additionalActions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await clearApplicationCache();
              showSuccessSnackBar(context, 'تم مسح ذاكرة التخزين المؤقت');
            },
            child: Text('مسح ذاكرة التخزين'),
          ),
        ],
      );
      return true;
    }
    
    return false;
  }

  static Future<void> performSafeOperation(
    BuildContext context,
    Future<void> Function() operation, {
    String? successMessage,
    String? operationName,
    bool showSuccessMessage = true,
    bool clearCacheOnError = false,
  }) async {
    try {
      await operation();
      
      if (showSuccessMessage && successMessage != null) {
        showSuccessSnackBar(context, successMessage);
      }
    } catch (error, stackTrace) {
      logError(operationName ?? 'Unknown operation', error, stackTrace);
      
      if (clearCacheOnError) {
        try {
          await clearApplicationCache();
        } catch (cacheError) {
          logError('Cache clearing', cacheError);
        }
      }
      
      final handled = await handleNetworkError(context, error);
      if (!handled) {
        showErrorDialog(context, error, title: operationName);
      }
    }
  }
}

extension ControllerErrorHandling on ChangeNotifier {
  Future<T?> handleOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? successMessage,
    String? operationName,
    bool showErrorDialog = false,
    bool clearCacheOnError = true,
  }) async {
    try {
      final result = await operation();
      
      if (clearCacheOnError) {
        await ErrorHandler.clearApplicationCache();
      }
      
      if (successMessage != null) {
        ErrorHandler.showSuccessSnackBar(context, successMessage);
      }
      
      return result;
    } catch (error, stackTrace) {
      ErrorHandler.logError(operationName ?? 'Controller operation', error, stackTrace);
      
      if (clearCacheOnError) {
        try {
          await ErrorHandler.clearApplicationCache();
        } catch (cacheError) {
          ErrorHandler.logError('Cache clearing', cacheError);
        }
      }
      
      if (showErrorDialog) {
        ErrorHandler.showErrorDialog(context, error, title: operationName);
      } else {
        final handled = await ErrorHandler.handleNetworkError(context, error);
        if (!handled) {
          ErrorHandler.showErrorSnackBar(context, error);
        }
      }
      
      return null;
    }
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final void Function(dynamic error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      
      if (widget.onError != null) {
        widget.onError!(details.exception, details.stack!);
      }
      
      ErrorHandler.logError('Flutter Error', details.exception, details.stack);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error);
      }
      
      return Scaffold(
        appBar: AppBar(
          title: Text('خطأ في التطبيق'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 100, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  ErrorHandler.getArabicErrorMessage(_error),
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}