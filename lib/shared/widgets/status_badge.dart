import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getStatusColor(status);
    final text = Helpers.getStatusText(status);
    final icon = Helpers.getStatusIcon(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckStatusBadge extends StatelessWidget {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final double fontSize;

  const CheckStatusBadge({
    super.key,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (!hasCheckedIn) {
      color = Colors.grey;
      text = 'Chưa vào';
      icon = Icons.schedule;
    } else if (!hasCheckedOut) {
      color = Colors.orange;
      text = 'Đang trong bãi';
      icon = Icons.login;
    } else {
      color = Colors.green;
      text = 'Đã ra';
      icon = Icons.logout;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
