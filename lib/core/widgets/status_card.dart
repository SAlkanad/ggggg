import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../utils/status_calculator.dart';

class StatusCard extends StatelessWidget {
  final ClientStatus status;
  final int daysRemaining;

  const StatusCard({
    Key? key,
    required this.status,
    required this.daysRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = StatusCalculator.getStatusColor(status);
    String text = StatusCalculator.getStatusText(status);
    IconData icon;

    switch (status) {
      case ClientStatus.green:
        icon = Icons.check_circle;
        break;
      case ClientStatus.yellow:
        icon = Icons.warning;
        break;
      case ClientStatus.red:
        icon = Icons.error;
        break;
      case ClientStatus.white:
        icon = Icons.flight_takeoff;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            status == ClientStatus.white ? text : '$text ($daysRemaining يوم)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}