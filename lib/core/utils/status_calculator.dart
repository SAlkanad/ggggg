import '../../models/client_model.dart';
import 'package:flutter/material.dart';

class StatusCalculator {
  static ClientStatus calculateStatus(DateTime entryDate, {
    int greenDays = 30,
    int yellowDays = 30,
    int redDays = 1,
  }) {
    final daysRemaining = calculateDaysRemaining(entryDate);
    
    if (daysRemaining > greenDays) {
      return ClientStatus.green;
    } else if (daysRemaining > redDays) {
      return ClientStatus.yellow;
    } else if (daysRemaining >= 0) {
      return ClientStatus.red;
    } else {
      return ClientStatus.red; // Expired
    }
  }

  static int calculateDaysRemaining(DateTime entryDate) {
    final now = DateTime.now();
    final visaExpiry = entryDate.add(Duration(days: 90)); // 90-day visa
    return visaExpiry.difference(now).inDays;
  }

  static String getStatusText(ClientStatus status) {
    switch (status) {
      case ClientStatus.green:
        return 'آمن';
      case ClientStatus.yellow:
        return 'تحذير';
      case ClientStatus.red:
        return 'خطر';
      case ClientStatus.white:
        return 'خرج';
    }
  }

  static Color getStatusColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.green:
        return Colors.green;
      case ClientStatus.yellow:
        return Colors.orange;
      case ClientStatus.red:
        return Colors.red;
      case ClientStatus.white:
        return Colors.grey;
    }
  }

  static bool isExpired(DateTime entryDate) {
    return calculateDaysRemaining(entryDate) < 0;
  }

  static bool isExpiringSoon(DateTime entryDate, int warningDays) {
    final daysRemaining = calculateDaysRemaining(entryDate);
    return daysRemaining <= warningDays && daysRemaining >= 0;
  }
}