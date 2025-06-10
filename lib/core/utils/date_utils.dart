import 'package:intl/intl.dart';

String formatArabicDate(DateTime date) {
  try {
    final formatter = DateFormat('yyyy/MM/dd', 'ar');
    return formatter.format(date);
  } catch (e) {
    // Fallback if Arabic locale is not available
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
  }
}

String formatTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return 'منذ ${difference.inDays} يوم';
  } else if (difference.inHours > 0) {
    return 'منذ ${difference.inHours} ساعة';
  } else if (difference.inMinutes > 0) {
    return 'منذ ${difference.inMinutes} دقيقة';
  } else {
    return 'الآن';
  }
}

String formatDateTime(DateTime date) {
  try {
    final formatter = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    return formatter.format(date);
  } catch (e) {
    // Fallback if Arabic locale is not available
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    return formatter.format(date);
  }
}

String formatTime(DateTime date) {
  try {
    final formatter = DateFormat('HH:mm', 'ar');
    return formatter.format(date);
  } catch (e) {
    // Fallback if Arabic locale is not available
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }
}

DateTime parseArabicDate(String dateString) {
  try {
    final formatter = DateFormat('yyyy/MM/dd', 'ar');
    return formatter.parse(dateString);
  } catch (e) {
    // Fallback if Arabic locale is not available
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.parse(dateString);
  }
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

bool isToday(DateTime date) {
  return isSameDay(date, DateTime.now());
}

bool isTomorrow(DateTime date) {
  final tomorrow = DateTime.now().add(Duration(days: 1));
  return isSameDay(date, tomorrow);
}

bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  return isSameDay(date, yesterday);
}