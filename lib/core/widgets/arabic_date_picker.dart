import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // <-- الخطوة 1: إضافة هذا السطر

class ArabicDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const ArabicDatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.label,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        title: Text(label),
        subtitle: Text(_formatArabicDate(selectedDate)),
        leading: Icon(Icons.calendar_today),
        trailing: Icon(Icons.edit),
        onTap: enabled ? () => _selectDate(context) : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(Duration(days: 365)),
      locale: Locale('ar', 'SA'),
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'موافق',
      fieldLabelText: 'أدخل التاريخ',
      fieldHintText: 'يوم/شهر/سنة',
      errorFormatText: 'تنسيق التاريخ غير صحيح',
      errorInvalidText: 'التاريخ غير صحيح',
      builder: (context, child) {
        return Directionality(
          // <-- الخطوة 2: استخدام البادئة هنا
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  String _formatArabicDate(DateTime date) {
    try {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (e) {
      // Fallback if Arabic locale is not available
      return DateFormat('yyyy/MM/dd').format(date);
    }
  }
}
