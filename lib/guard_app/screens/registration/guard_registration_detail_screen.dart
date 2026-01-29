import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class GuardRegistrationDetailScreen extends StatefulWidget {
  final GateAccessRegistrationModel registration;

  const GuardRegistrationDetailScreen({super.key, required this.registration});

  @override
  State<GuardRegistrationDetailScreen> createState() =>
      _GuardRegistrationDetailScreenState();
}

class _GuardRegistrationDetailScreenState
    extends State<GuardRegistrationDetailScreen> {
  late GateAccessRegistrationModel _registration;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _registration = widget.registration;
  }

  // Check-in visitor
  Future<void> _handleCheckIn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Check-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn chắc chắn muốn cho khách này vào trong khu vực?'),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khách: ${_registration.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('SĐT: ${_registration.phone}'),
                  if (_registration.idCard != null)
                    Text('CCCD: ${_registration.idCard}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final guard = context.read<AuthProvider>().user;

        await _firestoreService.checkInVisitor(
          registrationId: _registration.id,
          guardId: guard?.id ?? '',
          guardName: guard?.fullName,
        );

        // Reload registration data
        final updated = await _firestoreService.getGateAccessRegistrationById(
          _registration.id,
        );
        if (updated != null && mounted) {
          setState(() {
            _registration = updated;
            _isLoading = false;
          });
          Helpers.showSuccessSnackBar(
            context,
            'Check-in thành công! Khách đang viếng thăm.',
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          Helpers.showErrorSnackBar(context, 'Lỗi: ${e.toString()}');
        }
      }
    }
  }

  // Check-out visitor
  Future<void> _handleCheckOut() async {
    // Show checkout dialog with confirmations
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => _CheckOutDialog(registration: _registration),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);

      try {
        final guard = context.read<AuthProvider>().user;

        await _firestoreService.checkOutVisitor(
          registrationId: _registration.id,
          guardId: guard?.id ?? '',
          guardName: guard?.fullName,
          accessCardReturned: result['accessCardReturned'] ?? false,
          idCardReturned: result['idCardReturned'] ?? false,
        );

        // Reload registration data
        final updated = await _firestoreService.getGateAccessRegistrationById(
          _registration.id,
        );
        if (updated != null && mounted) {
          setState(() {
            _registration = updated;
            _isLoading = false;
          });
          Helpers.showSuccessSnackBar(context, 'Check-out thành công!');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          Helpers.showErrorSnackBar(context, 'Lỗi: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đăng ký'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Check-in Button (if approved and not checked in yet)
            if (_registration.isApproved && !_registration.hasCheckedIn)
              _buildCheckInButton(),
            if (_registration.isApproved && !_registration.hasCheckedIn)
              const SizedBox(height: 16),

            // Check-out Button (if currently inside - checked in but not checked out)
            if (_registration.isCurrentlyInside) _buildCheckOutButton(),
            if (_registration.isCurrentlyInside) const SizedBox(height: 16),

            // QR Code Card (if approved)
            if (_registration.isApproved && _registration.qrCode != null)
              _buildQRCard(),
            if (_registration.isApproved && _registration.qrCode != null)
              const SizedBox(height: 16),

            // Personal Info Card
            _buildSectionCard(
              title: 'Thông tin cá nhân',
              icon: Icons.person,
              children: [
                _buildInfoRow('Họ tên', _registration.fullName),
                _buildInfoRow('Số điện thoại', _registration.phone),
                if (_registration.email != null)
                  _buildInfoRow('Email', _registration.email!),
                if (_registration.idCard != null)
                  _buildInfoRow('CCCD/CMND', _registration.idCard!),
                if (_registration.addressOrCompany != null)
                  _buildInfoRow(
                    'Địa chỉ/Công ty',
                    _registration.addressOrCompany!,
                  ),
                if (_registration.address != null &&
                    _registration.addressOrCompany == null)
                  _buildInfoRow('Địa chỉ', _registration.address!),
                if (_registration.companyName != null &&
                    _registration.addressOrCompany == null)
                  _buildInfoRow('Công ty', _registration.companyName!),
                _buildInfoRow('Loại', _registration.visitorTypeDisplay),
                if (_registration.idCardHeldByGuard)
                  _buildInfoRow(
                    'Giữ CCCD',
                    'Bảo vệ đang giữ CCCD',
                    valueColor: Colors.orange,
                  ),
                if (_registration.photoUrl != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Ảnh CCCD/CMND',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _registration.photoUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Access Card Info (if issued)
            if (_registration.accessCardIssued)
              _buildSectionCard(
                title: 'Thẻ ra vào',
                icon: Icons.credit_card,
                children: [
                  _buildInfoRow(
                    'Trạng thái',
                    'Đã cấp thẻ',
                    valueColor: Colors.blue,
                  ),
                  if (_registration.accessCardNumber != null)
                    _buildInfoRow('Mã thẻ', _registration.accessCardNumber!),
                ],
              ),
            if (_registration.accessCardIssued) const SizedBox(height: 16),

            // Time Info Card
            _buildSectionCard(
              title: 'Thời gian',
              icon: Icons.schedule,
              children: [
                _buildInfoRow('Loại đăng ký', _registration.accessTypeDisplay),
                _buildInfoRow('Ngày', _registration.expectedDateDisplay),
                _buildInfoRow('Thời gian', _registration.expectedTimeDisplay),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle Info Card (if has vehicle)
            if (_registration.hasVehicle)
              _buildSectionCard(
                title: 'Phương tiện',
                icon: _registration.vehicleType == 'car'
                    ? Icons.directions_car
                    : Icons.two_wheeler,
                children: [
                  _buildInfoRow(
                    'Loại xe',
                    _registration.vehicleTypeDisplay ?? '',
                  ),
                  _buildInfoRow('Biển số', _registration.vehiclePlate ?? ''),
                ],
              ),
            if (_registration.hasVehicle) const SizedBox(height: 16),

            // Purpose Info Card
            _buildSectionCard(
              title: 'Mục đích',
              icon: Icons.description,
              children: [
                _buildInfoRow('Mục đích', _registration.purpose),
                if (_registration.visitDepartment != null)
                  _buildInfoRow('Phòng ban', _registration.visitDepartment!),
                if (_registration.hostName != null)
                  _buildInfoRow('Người tiếp đón', _registration.hostName!),
                if (_registration.hostPhone != null)
                  _buildInfoRow('SĐT liên hệ', _registration.hostPhone!),
                if (_registration.note != null)
                  _buildInfoRow('Ghi chú', _registration.note!),
              ],
            ),
            const SizedBox(height: 16),

            // Check-in/out Info (if has checked)
            if (_registration.hasCheckedIn)
              _buildSectionCard(
                title: 'Lịch sử ra/vào',
                icon: Icons.history,
                children: [
                  if (_registration.actualCheckInTime != null)
                    _buildInfoRow(
                      'Check-in',
                      Helpers.formatDateTime(_registration.actualCheckInTime!),
                      valueColor: Colors.green,
                    ),
                  if (_registration.actualCheckOutTime != null)
                    _buildInfoRow(
                      'Check-out',
                      Helpers.formatDateTime(_registration.actualCheckOutTime!),
                      valueColor: Colors.orange,
                    ),
                  if (_registration.isCurrentlyInside)
                    _buildInfoRow(
                      'Trạng thái',
                      'Đang viếng thăm',
                      valueColor: Colors.green,
                    ),
                ],
              ),
            if (_registration.hasCheckedIn) const SizedBox(height: 16),

            // System Info Card
            _buildSectionCard(
              title: 'Thông tin hệ thống',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Mã đăng ký', _registration.id),
                _buildInfoRow('Ngày tạo', _registration.createdAtDisplay),
                if (_registration.isRegisteredByGuard)
                  _buildInfoRow('Nguồn', 'Đăng ký bởi bảo vệ'),
                if (_registration.isRegisteredByUser)
                  _buildInfoRow('Nguồn', 'Đăng ký qua app'),
                if (_registration.approvedByName != null)
                  _buildInfoRow('Duyệt bởi', _registration.approvedByName!),
                if (_registration.approvedAt != null)
                  _buildInfoRow(
                    'Ngày duyệt',
                    Helpers.formatDateTime(_registration.approvedAt!),
                  ),
                if (_registration.rejectionReason != null)
                  _buildInfoRow(
                    'Lý do từ chối',
                    _registration.rejectionReason!,
                    valueColor: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.how_to_reg, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'Khách đã được duyệt và sẵn sàng check-in',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleCheckIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoading ? 'Đang xử lý...' : 'Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOutButton() {
    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.exit_to_app, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Khách đang ở trong khu vực',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleCheckOut,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoading ? 'Đang xử lý...' : 'Check-out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_registration.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Chờ duyệt';
        statusDescription = 'Đăng ký đang chờ được phê duyệt';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = _registration.hasCheckedIn
            ? 'Đang viếng thăm'
            : 'Đã duyệt';
        statusDescription = _registration.hasCheckedIn
            ? (_registration.hasCheckedOut
                  ? 'Khách đã check-out'
                  : 'Khách đang ở trong khu vực')
            : 'Khách có thể vào cổng';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Từ chối';
        statusDescription =
            _registration.rejectionReason ?? 'Đăng ký bị từ chối';
        break;
      case 'used':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Đã sử dụng';
        statusDescription = 'Đăng ký đã được sử dụng';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off;
        statusText = 'Hết hạn';
        statusDescription = 'Đăng ký đã hết hạn';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = 'Đã hủy';
        statusDescription = 'Đăng ký đã bị hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = _registration.status;
        statusDescription = '';
    }

    final cardColor = Helpers.getCardBackgroundFromStatus(statusColor);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor.withOpacity(0.85),
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

  Widget _buildQRCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Mã QR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: _registration.qrCode!,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (_registration.qrExpiresAt != null)
              Text(
                'Hết hạn: ${Helpers.formatDateTime(_registration.qrExpiresAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _registration.isQRExpired
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.guardPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.guardPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog for checkout confirmation
class _CheckOutDialog extends StatefulWidget {
  final GateAccessRegistrationModel registration;

  const _CheckOutDialog({required this.registration});

  @override
  State<_CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends State<_CheckOutDialog> {
  bool _accessCardReturned = false;
  bool _idCardReturned = false;

  bool get _needsAccessCardReturn => widget.registration.accessCardIssued;

  bool get _needsIdCardReturn => widget.registration.idCardHeldByGuard;

  bool get _canConfirm {
    // If access card was issued, must confirm return
    if (_needsAccessCardReturn && !_accessCardReturned) return false;
    // If ID card was held, must confirm return
    if (_needsIdCardReturn && !_idCardReturned) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận Check-out'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visitor info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khách: ${widget.registration.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('SĐT: ${widget.registration.phone}'),
                  if (widget.registration.idCard != null)
                    Text('CCCD: ${widget.registration.idCard}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Check-in time info
            if (widget.registration.actualCheckInTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.login, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Check-in: ${Helpers.formatDateTime(widget.registration.actualCheckInTime!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Confirmation checkboxes
            if (_needsAccessCardReturn || _needsIdCardReturn) ...[
              const Text(
                'Xác nhận trả lại:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Access card return checkbox
              if (_needsAccessCardReturn)
                CheckboxListTile(
                  value: _accessCardReturned,
                  onChanged: (value) {
                    setState(() {
                      _accessCardReturned = value ?? false;
                    });
                  },
                  title: Row(
                    children: [
                      const Icon(Icons.badge, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã trả thẻ ra vào${widget.registration.accessCardNumber != null ? ' (${widget.registration.accessCardNumber})' : ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Bắt buộc',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

              // ID card return checkbox
              if (_needsIdCardReturn)
                CheckboxListTile(
                  value: _idCardReturned,
                  onChanged: (value) {
                    setState(() {
                      _idCardReturned = value ?? false;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.credit_card, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã trả CCCD/CMND',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Bắt buộc',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],

            // Warning if nothing to return
            if (!_needsAccessCardReturn && !_needsIdCardReturn)
              const Text(
                'Nhấn "Xác nhận" để hoàn tất check-out.',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _canConfirm
              ? () {
                  Navigator.pop(context, {
                    'accessCardReturned': _accessCardReturned,
                    'idCardReturned': _idCardReturned,
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
