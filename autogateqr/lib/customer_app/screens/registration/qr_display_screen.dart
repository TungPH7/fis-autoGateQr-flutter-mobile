import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/registration_model.dart';
import '../../../shared/widgets/qr_code_widget.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/qr_service.dart';

class QRDisplayScreen extends StatelessWidget {
  final RegistrationModel registration;

  const QRDisplayScreen({
    super.key,
    required this.registration,
  });

  void _shareQR() {
    final message = '''
Mã QR đăng ký ra/vào cổng
Biển số: ${registration.plateNumber}
Tài xế: ${registration.driverInfo.name}
Ngày: ${Helpers.formatDate(registration.expectedDate)}
Mục đích: ${registration.visitPurpose}

Vui lòng đưa mã QR này cho bảo vệ khi đến cổng.
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final qrData = registration.qrCode ?? QRService.generateRegistrationQRData(registration);
    final isExpired = registration.isQRExpired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR đăng ký'),
        actions: [
          if (!isExpired)
            IconButton(
              onPressed: _shareQR,
              icon: const Icon(Icons.share),
              tooltip: 'Chia sẻ',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code
            QRCodeWidget(
              data: qrData,
              size: 280,
              title: registration.plateNumber,
              subtitle: registration.driverInfo.name,
              expiresAt: registration.qrExpiresAt,
            ),
            const SizedBox(height: 32),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.directions_car,
                      'Biển số',
                      registration.plateNumber ?? 'N/A',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.person,
                      'Tài xế',
                      registration.driverInfo.name,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.phone,
                      'SĐT',
                      registration.driverInfo.phone,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Ngày',
                      Helpers.formatDate(registration.expectedDate),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.description,
                      'Mục đích',
                      registration.visitPurpose,
                    ),
                    if (registration.companyName != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.business,
                        'Công ty',
                        registration.companyName!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 8),
                      const Text(
                        'Hướng dẫn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Đưa mã QR này cho bảo vệ khi đến cổng\n'
                    '2. Bảo vệ sẽ quét mã để xác nhận thông tin\n'
                    '3. Sau khi xác nhận, bạn được phép ra/vào',
                    style: TextStyle(
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share button
            if (!isExpired)
              CustomButton(
                text: 'Chia sẻ mã QR',
                onPressed: _shareQR,
                icon: Icons.share,
                width: double.infinity,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}