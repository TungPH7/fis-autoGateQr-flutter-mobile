import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final String? title;
  final String? subtitle;
  final DateTime? expiresAt;
  final Color? backgroundColor;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 250,
    this.title,
    this.subtitle,
    this.expiresAt,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt!);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // QR Code
          Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Không thể tạo mã QR',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (isExpired)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Mã QR đã hết hạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Expiry info
          if (expiresAt != null && !isExpired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hết hạn: ${Helpers.formatDateTime(expiresAt!)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ],
              ),
            ),
          ],

          if (isExpired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text(
                    'Mã QR đã hết hạn',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QRCodeDialog extends StatelessWidget {
  final String data;
  final String? title;
  final String? plateNumber;
  final DateTime? expiresAt;

  const QRCodeDialog({
    super.key,
    required this.data,
    this.title,
    this.plateNumber,
    this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? 'Mã QR',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            QRCodeWidget(
              data: data,
              size: 220,
              subtitle: plateNumber,
              expiresAt: expiresAt,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đưa mã này cho bảo vệ để quét khi vào cổng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
