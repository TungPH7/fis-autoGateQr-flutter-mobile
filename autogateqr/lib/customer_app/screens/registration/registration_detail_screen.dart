import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/registration_model.dart';
import '../../../providers/registration_provider.dart';
import '../../../shared/widgets/qr_code_widget.dart';

class RegistrationDetailScreen extends StatelessWidget {
  final RegistrationModel registration;

  const RegistrationDetailScreen({
    super.key,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đăng ký'),
        actions: [
          if (registration.isApproved && registration.hasValidQR)
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQRDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildInfoSection(
              context,
              'Thông tin xe',
              Icons.directions_car,
              [
                _buildInfoRow('Biển số xe', registration.plateNumber ?? 'N/A'),
                _buildInfoRow('Loại xe', _getVehicleTypeText(registration.vehicleType)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              context,
              'Thông tin tài xế',
              Icons.person,
              [
                _buildInfoRow('Họ tên', registration.driverInfo.name),
                _buildInfoRow('Số điện thoại', registration.driverInfo.phone),
                if (registration.driverInfo.license != null)
                  _buildInfoRow('Số GPLX', registration.driverInfo.license!),
                if (registration.driverInfo.idCard != null)
                  _buildInfoRow('CMND/CCCD', registration.driverInfo.idCard!),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              context,
              'Thông tin đăng ký',
              Icons.assignment,
              [
                _buildInfoRow('Mục đích', registration.visitPurpose),
                if (registration.visitLocation != null)
                  _buildInfoRow('Địa điểm', registration.visitLocation!),
                _buildInfoRow('Ngày dự kiến', DateFormat('dd/MM/yyyy').format(registration.expectedDate)),
                if (registration.expectedTimeFrom != null)
                  _buildInfoRow('Giờ từ', DateFormat('HH:mm').format(registration.expectedTimeFrom!)),
                if (registration.expectedTimeTo != null)
                  _buildInfoRow('Giờ đến', DateFormat('HH:mm').format(registration.expectedTimeTo!)),
                _buildInfoRow('Loại đăng ký', _getRegistrationTypeText(registration.registrationType)),
              ],
            ),
            if (registration.cargoInfo != null && registration.cargoInfo!.description != null) ...[
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Thông tin hàng hóa',
                Icons.inventory,
                [
                  if (registration.cargoInfo!.description != null)
                    _buildInfoRow('Mô tả', registration.cargoInfo!.description!),
                  if (registration.cargoInfo!.weight != null)
                    _buildInfoRow('Trọng lượng', '${registration.cargoInfo!.weight} kg'),
                  if (registration.cargoInfo!.containerNumber != null)
                    _buildInfoRow('Số container', registration.cargoInfo!.containerNumber!),
                  if (registration.cargoInfo!.sealNumber != null)
                    _buildInfoRow('Số seal', registration.cargoInfo!.sealNumber!),
                ],
              ),
            ],
            if (registration.notes != null && registration.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Ghi chú',
                Icons.note,
                [
                  _buildInfoRow('', registration.notes!),
                ],
              ),
            ],
            if (registration.isApproved) ...[
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Thông tin phê duyệt',
                Icons.check_circle,
                [
                  if (registration.approvedByName != null)
                    _buildInfoRow('Người duyệt', registration.approvedByName!),
                  if (registration.approvedAt != null)
                    _buildInfoRow('Thời gian', DateFormat('dd/MM/yyyy HH:mm').format(registration.approvedAt!)),
                  if (registration.qrExpiresAt != null)
                    _buildInfoRow('QR hết hạn', DateFormat('dd/MM/yyyy HH:mm').format(registration.qrExpiresAt!)),
                ],
              ),
            ],
            if (registration.isRejected && registration.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _buildInfoSection(
                context,
                'Lý do từ chối',
                Icons.cancel,
                [
                  _buildInfoRow('', registration.rejectionReason!),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoSection(
              context,
              'Thời gian',
              Icons.access_time,
              [
                _buildInfoRow('Tạo lúc', DateFormat('dd/MM/yyyy HH:mm').format(registration.createdAt)),
                if (registration.updatedAt != null)
                  _buildInfoRow('Cập nhật', DateFormat('dd/MM/yyyy HH:mm').format(registration.updatedAt!)),
              ],
            ),
            const SizedBox(height: 24),
            if (registration.isApproved && registration.hasValidQR)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showQRDialog(context),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Hiển thị mã QR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (registration.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Chờ duyệt';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Từ chối';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Hoàn thành';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off;
        statusText = 'Hết hạn';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Không xác định';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    registration.plateNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeText(String? type) {
    switch (type) {
      case 'car':
        return 'Ô tô';
      case 'truck':
        return 'Xe tải';
      case 'container':
        return 'Container';
      case 'motorcycle':
        return 'Xe máy';
      default:
        return type ?? 'N/A';
    }
  }

  String _getRegistrationTypeText(String type) {
    switch (type) {
      case 'entry':
        return 'Vào';
      case 'exit':
        return 'Ra';
      case 'both':
        return 'Ra/Vào';
      default:
        return type;
    }
  }

  void _showQRDialog(BuildContext context) {
    final qrData = context.read<RegistrationProvider>().getQRDataForDisplay(registration);
    if (qrData == null) return;

    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        data: qrData,
        title: 'Mã QR đăng ký',
        plateNumber: registration.plateNumber,
        expiresAt: registration.qrExpiresAt,
      ),
    );
  }
}
