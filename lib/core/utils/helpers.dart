import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class Helpers {
  Helpers._();

  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $remainingMinutes phút';
  }

  static String getDurationBetween(DateTime from, DateTime to) {
    if (to.isBefore(from)) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    final diff = to.difference(from);

    // < 1 day → chi tiết tới giây
    if (diff.inDays == 0) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final parts = <String>[];

      if (hours > 0) parts.add('$hours giờ');
      if (minutes > 0) parts.add('$minutes phút');

      return parts.join(' ');
    }

    // >= 1 day và < 1 month
    if (diff.inDays < 30) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;

      final parts = <String>[];
      parts.add('$days ngày');
      if (hours > 0) parts.add('$hours giờ');
      return parts.join(' ');
    }

    // >= 1 month → tính theo calendar
    int years = to.year - from.year;
    int months = to.month - from.month;
    int days = to.day - from.day;

    if (days < 0) {
      months--;
      final prevMonth = DateTime(to.year, to.month, 0);
      days += prevMonth.day;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years năm');
    if (months > 0) parts.add('$months tháng');
    if (days > 0) parts.add('$days ngày');

    return parts.join(' ');
  }

  // Status Helpers
  static String getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Chờ duyệt';
      case AppConstants.statusApproved:
        return 'Đã duyệt';
      case AppConstants.statusRejected:
        return 'Từ chối';
      case AppConstants.statusCompleted:
        return 'Hoàn thành';
      case AppConstants.statusExpired:
        return 'Hết hạn';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusApproved:
        return AppColors.statusApproved;
      case AppConstants.statusRejected:
        return AppColors.statusRejected;
      case AppConstants.statusCompleted:
        return AppColors.statusCompleted;
      case AppConstants.statusExpired:
        return AppColors.statusExpired;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color getCardBackgroundFromStatus(Color statusColor) {
    if (statusColor == Colors.orange) return const Color(0xFFFFF4E5);
    if (statusColor == Colors.green) return const Color(0xFFE6F4EA);
    if (statusColor == Colors.red) return const Color(0xFFFDECEA);
    if (statusColor == Colors.blue) return const Color(0xFFE8F1FD);
    if (statusColor == Colors.grey) return const Color(0xFFF5F5F5);

    // default fallback
    return const Color(0xFFF5F5F5);
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.schedule;
      case AppConstants.statusApproved:
        return Icons.check_circle;
      case AppConstants.statusRejected:
        return Icons.cancel;
      case AppConstants.statusCompleted:
        return Icons.done_all;
      case AppConstants.statusExpired:
        return Icons.timer_off;
      default:
        return Icons.info;
    }
  }

  // Registration Type Helpers
  static String getRegistrationTypeText(String type) {
    switch (type) {
      case AppConstants.regTypeEntry:
        return 'Vào cổng';
      case AppConstants.regTypeExit:
        return 'Ra cổng';
      case AppConstants.regTypeBoth:
        return 'Ra/Vào';
      default:
        return type;
    }
  }

  // Plate Number Normalization
  static String normalizePlateNumber(String plateNumber) {
    return plateNumber.toUpperCase().replaceAll(' ', '').replaceAll('.', '');
  }

  // Snackbar Helpers
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, isError: true);
  }

  // Dialog Helpers
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDanger
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Loading Dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message ?? 'Đang xử lý...'),
            ],
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }
}
