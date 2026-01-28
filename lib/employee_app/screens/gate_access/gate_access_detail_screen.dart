import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/gate_access_provider.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class GateAccessDetailScreen extends StatelessWidget {
  final GateAccessRegistrationModel registration;

  const GateAccessDetailScreen({
    super.key,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đăng ký'),
        actions: [
          if (registration.isPending)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showCancelDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            if (registration.hasValidQR) ...[
              _buildQRCard(context),
              const SizedBox(height: 16),
            ],
            _buildPersonalInfoCard(context),
            const SizedBox(height: 16),
            _buildTimeCard(context),
            const SizedBox(height: 16),
            _buildPurposeCard(context),
            if (registration.isRejected &&
                registration.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _buildRejectionCard(context),
            ],
            if (registration.approvedAt != null) ...[
              const SizedBox(height: 16),
              _buildApprovalCard(context),
            ],
            if (registration.hasCheckedIn) ...[
              const SizedBox(height: 16),
              _buildCheckInOutCard(context),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (registration.status) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        message = 'Đang chờ Admin duyệt. Bạn sẽ nhận được thông báo khi đăng ký được duyệt.';
        break;
      case 'approved':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        message = registration.hasValidQR
            ? 'Đăng ký đã được duyệt. Đưa mã QR bên dưới cho bảo vệ để quét.'
            : 'Đăng ký đã được duyệt nhưng QR đã hết hạn.';
        break;
      case 'rejected':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        message = 'Đăng ký đã bị từ chối.';
        break;
      case 'expired':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.timer_off;
        message = 'Đăng ký đã hết hạn.';
        break;
      case 'used':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.done_all;
        message = 'Đăng ký đã được sử dụng.';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.block;
        message = 'Đăng ký đã bị hủy.';
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        message = 'Trạng thái không xác định.';
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registration.statusDisplay,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Mã QR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đưa mã này cho bảo vệ để quét',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: registration.qrCode!,
                version: QrVersions.auto,
                size: 200,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            if (registration.qrExpiresAt != null) ...[
              const SizedBox(height: 16),
              _buildQRExpiryInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRExpiryInfo() {
    final now = DateTime.now();
    final expiresAt = registration.qrExpiresAt!;
    final isExpired = now.isAfter(expiresAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            size: 18,
            color: isExpired ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired
                ? 'QR đã hết hạn'
                : 'Hết hạn: ${_formatDateTime(expiresAt)}',
            style: TextStyle(
              color: isExpired ? Colors.red : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    registration.visitorTypeDisplay,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Họ tên', registration.fullName),
            _buildInfoRow('SĐT', registration.phone),
            if (registration.email != null)
              _buildInfoRow('Email', registration.email!),
            if (registration.idCard != null)
              _buildInfoRow('CCCD', registration.idCardMasked ?? registration.idCard!),
            if (registration.address != null)
              _buildInfoRow('Địa chỉ', registration.address!),
            if (registration.companyName != null)
              _buildInfoRow('Công ty', registration.companyName!),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thời gian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Loại', registration.accessTypeDisplay),
            _buildInfoRow('Ngày', registration.expectedDateDisplay),
            _buildInfoRow('Thời gian', registration.expectedTimeDisplay),
            _buildInfoRow('Ngày tạo', registration.createdAtDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Mục đích',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Mục đích', registration.purpose),
            if (registration.visitDepartment != null)
              _buildInfoRow('Phòng ban', registration.visitDepartment!),
            if (registration.hostName != null)
              _buildInfoRow('Người tiếp đón', registration.hostName!),
            if (registration.hostPhone != null)
              _buildInfoRow('SĐT liên hệ', registration.hostPhone!),
            if (registration.note != null)
              _buildInfoRow('Ghi chú', registration.note!),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionCard(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Lý do từ chối',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              registration.rejectionReason!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Thông tin duyệt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (registration.approvedByName != null)
              _buildInfoRow('Người duyệt', registration.approvedByName!),
            _buildInfoRow(
              'Thời gian duyệt',
              _formatDateTime(registration.approvedAt!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInOutCard(BuildContext context) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Lịch sử ra/vào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (registration.actualCheckInTime != null)
              _buildInfoRow(
                'Check-in',
                _formatDateTime(registration.actualCheckInTime!),
              ),
            if (registration.actualCheckOutTime != null)
              _buildInfoRow(
                'Check-out',
                _formatDateTime(registration.actualCheckOutTime!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: const Text('Bạn có chắc muốn hủy đăng ký này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<GateAccessProvider>();
              final success =
                  await provider.cancelRegistration(registration.id);
              if (success && context.mounted) {
                Helpers.showSuccessSnackBar(context, 'Đã hủy đăng ký');
                Navigator.pop(context);
              } else if (provider.errorMessage != null && context.mounted) {
                Helpers.showErrorSnackBar(context, provider.errorMessage!);
              }
            },
            child: const Text(
              'Hủy đăng ký',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
