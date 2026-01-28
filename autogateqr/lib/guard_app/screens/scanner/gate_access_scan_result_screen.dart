import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gate_access_check_in_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class GateAccessScanResultScreen extends StatefulWidget {
  const GateAccessScanResultScreen({super.key});

  @override
  State<GateAccessScanResultScreen> createState() =>
      _GateAccessScanResultScreenState();
}

class _GateAccessScanResultScreenState
    extends State<GateAccessScanResultScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _accessCardController = TextEditingController();

  bool _holdIdCard = false;
  bool _returnIdCard = false;
  bool _returnAccessCard = false;

  @override
  void dispose() {
    _noteController.dispose();
    _accessCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin đăng ký'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GateAccessCheckInProvider>(
        builder: (context, provider, _) {
          final registration = provider.scannedRegistration;

          if (registration == null) {
            return const Center(
              child: Text('Không có thông tin'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(provider),
                const SizedBox(height: 16),

                // Visitor info card
                _buildVisitorInfoCard(provider),
                const SizedBox(height: 16),

                // Visit details card
                _buildVisitDetailsCard(provider),
                const SizedBox(height: 16),

                // Gate selection
                _buildGateSelection(provider),
                const SizedBox(height: 16),

                // Additional options
                _buildAdditionalOptions(provider),
                const SizedBox(height: 16),

                // Messages
                _buildMessages(provider),

                // Action buttons
                _buildActionButtons(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(GateAccessCheckInProvider provider) {
    final canCheckIn = provider.canCheckIn;
    final canCheckOut = provider.canCheckOut;
    final registration = provider.scannedRegistration!;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (canCheckIn) {
      statusColor = AppColors.success;
      statusIcon = Icons.login;
      statusTitle = 'Sẵn sàng Check-in';
      statusSubtitle = registration.fullName;
    } else if (canCheckOut) {
      statusColor = Colors.orange;
      statusIcon = Icons.logout;
      statusTitle = 'Sẵn sàng Check-out';
      statusSubtitle = registration.fullName;
    } else {
      statusColor = AppColors.info;
      statusIcon = Icons.info;
      statusTitle = provider.getStatusText();
      statusSubtitle = registration.fullName;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusSubtitle,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorInfoCard(GateAccessCheckInProvider provider) {
    final registration = provider.scannedRegistration!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông tin khách',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildVisitorTypeBadge(registration.visitorType),
              ],
            ),
            const Divider(height: 24),

            // Avatar and name
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _getVisitorTypeColor(registration.visitorType)
                      .withValues(alpha: 0.1),
                  child: Icon(
                    _getVisitorTypeIcon(registration.visitorType),
                    size: 36,
                    color: _getVisitorTypeColor(registration.visitorType),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        registration.phone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            if (registration.idCard != null && registration.idCard!.isNotEmpty)
              _buildInfoRow(
                Icons.credit_card,
                'CCCD/CMND',
                registration.idCardMasked ?? registration.idCard!,
              ),
            if (registration.addressOrCompany != null)
              _buildInfoRow(
                Icons.business,
                'Địa chỉ/Công ty',
                registration.addressOrCompany!,
              ),
            if (registration.email != null)
              _buildInfoRow(
                Icons.email,
                'Email',
                registration.email!,
              ),

            // Vehicle info
            if (registration.hasVehicle) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                registration.vehicleType == 'car'
                    ? Icons.directions_car
                    : Icons.two_wheeler,
                'Phương tiện',
                '${registration.vehicleTypeDisplay} - ${registration.vehiclePlate}',
              ),
            ],

            // Badges
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (registration.idCardHeldByGuard)
                  _buildBadge('Đang giữ CCCD', Colors.red, Icons.credit_card),
                if (registration.accessCardIssued)
                  _buildBadge(
                    'Thẻ: ${registration.accessCardNumber ?? 'N/A'}',
                    Colors.blue,
                    Icons.badge,
                  ),
                if (registration.isCurrentlyInside)
                  _buildBadge('Đang trong nhà máy', Colors.green, Icons.location_on),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDetailsCard(GateAccessCheckInProvider provider) {
    final registration = provider.scannedRegistration!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đăng ký',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),

            _buildInfoRow(
              Icons.calendar_today,
              'Ngày đăng ký',
              registration.expectedDateDisplay,
            ),
            _buildInfoRow(
              Icons.access_time,
              'Thời gian',
              registration.expectedTimeDisplay,
            ),
            _buildInfoRow(
              Icons.swap_horiz,
              'Loại đăng ký',
              registration.accessTypeDisplay,
            ),
            _buildInfoRow(
              Icons.description,
              'Mục đích',
              registration.purpose,
            ),
            if (registration.visitDepartment != null)
              _buildInfoRow(
                Icons.apartment,
                'Phòng ban',
                registration.visitDepartment!,
              ),
            if (registration.hostName != null)
              _buildInfoRow(
                Icons.person,
                'Người tiếp đón',
                registration.hostName!,
              ),
            if (registration.hostPhone != null)
              _buildInfoRow(
                Icons.phone,
                'SĐT liên hệ',
                registration.hostPhone!,
              ),

            // Check-in/out times
            if (registration.actualCheckInTime != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.login,
                'Check-in lúc',
                _formatDateTime(registration.actualCheckInTime!),
                valueColor: Colors.green,
              ),
            ],
            if (registration.actualCheckOutTime != null)
              _buildInfoRow(
                Icons.logout,
                'Check-out lúc',
                _formatDateTime(registration.actualCheckOutTime!),
                valueColor: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateSelection(GateAccessCheckInProvider provider) {
    // Ẩn phần chọn cổng nếu không có cổng nào
    if (provider.gates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn cổng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: provider.selectedGate?.id,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.door_sliding_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Chọn cổng'),
              isExpanded: true,
              items: provider.gates.map((gate) {
                return DropdownMenuItem<String>(
                  value: gate.id,
                  child: Row(
                    children: [
                      Icon(
                        gate.gateType == 'in'
                            ? Icons.login
                            : gate.gateType == 'out'
                                ? Icons.logout
                                : Icons.swap_horiz,
                        size: 20,
                        color: AppColors.guardPrimary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${gate.gateName} (${gate.gateTypeName})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (gateId) {
                if (gateId != null) {
                  final gate = provider.gates.firstWhere((g) => g.id == gateId);
                  provider.selectGate(gate);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions(GateAccessCheckInProvider provider) {
    final registration = provider.scannedRegistration!;
    final canCheckIn = provider.canCheckIn;
    final canCheckOut = provider.canCheckOut;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tùy chọn bổ sung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Check-in options
            if (canCheckIn) ...[
              // Hold ID card option
              CheckboxListTile(
                value: _holdIdCard,
                onChanged: (value) => setState(() => _holdIdCard = value ?? false),
                title: const Text('Giữ CCCD/CMND'),
                subtitle: const Text('Bảo vệ giữ giấy tờ tùy thân'),
                secondary: const Icon(Icons.credit_card, color: Colors.red),
                contentPadding: EdgeInsets.zero,
              ),

              // Access card option
              TextField(
                controller: _accessCardController,
                decoration: const InputDecoration(
                  labelText: 'Cấp thẻ ra vào (tùy chọn)',
                  hintText: 'Nhập mã thẻ...',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // Check-out options
            if (canCheckOut) ...[
              if (registration.idCardHeldByGuard)
                CheckboxListTile(
                  value: _returnIdCard,
                  onChanged: (value) =>
                      setState(() => _returnIdCard = value ?? false),
                  title: const Text('Trả CCCD/CMND'),
                  subtitle: const Text('Đã trả giấy tờ cho khách'),
                  secondary: const Icon(Icons.credit_card, color: Colors.green),
                  contentPadding: EdgeInsets.zero,
                ),
              if (registration.accessCardIssued)
                CheckboxListTile(
                  value: _returnAccessCard,
                  onChanged: (value) =>
                      setState(() => _returnAccessCard = value ?? false),
                  title: Text('Thu hồi thẻ (${registration.accessCardNumber})'),
                  subtitle: const Text('Đã thu hồi thẻ ra vào'),
                  secondary: const Icon(Icons.badge, color: Colors.blue),
                  contentPadding: EdgeInsets.zero,
                ),
            ],

            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Nhập ghi chú...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(GateAccessCheckInProvider provider) {
    return Column(
      children: [
        if (provider.successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        if (provider.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(GateAccessCheckInProvider provider) {
    return Column(
      children: [
        if (provider.canCheckIn)
          CustomButton(
            text: 'CHECK IN',
            onPressed: () => _performCheckIn(context),
            isLoading: provider.isProcessing,
            backgroundColor: AppColors.checkInColor,
            icon: Icons.login,
            width: double.infinity,
          ),
        if (provider.canCheckOut)
          CustomButton(
            text: 'CHECK OUT',
            onPressed: () => _performCheckOut(context),
            isLoading: provider.isProcessing,
            backgroundColor: AppColors.checkOutColor,
            icon: Icons.logout,
            width: double.infinity,
          ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Quét lại',
          onPressed: () {
            provider.clearScanData();
            Navigator.pop(context, false);
          },
          isOutlined: true,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorTypeBadge(String type) {
    final color = _getVisitorTypeColor(type);
    final text = _getVisitorTypeText(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVisitorTypeColor(String type) {
    switch (type) {
      case 'employee':
        return Colors.blue;
      case 'contractor':
        return Colors.orange;
      case 'visitor':
      default:
        return Colors.purple;
    }
  }

  IconData _getVisitorTypeIcon(String type) {
    switch (type) {
      case 'employee':
        return Icons.badge;
      case 'contractor':
        return Icons.engineering;
      case 'visitor':
      default:
        return Icons.person;
    }
  }

  String _getVisitorTypeText(String type) {
    switch (type) {
      case 'employee':
        return 'Nhân viên';
      case 'contractor':
        return 'Nhà thầu';
      case 'visitor':
      default:
        return 'Khách';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _performCheckIn(BuildContext context) async {
    final provider = context.read<GateAccessCheckInProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    final success = await provider.performCheckIn(
      guardId: user.uid,
      guardName: user.fullName,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      holdIdCard: _holdIdCard,
      accessCardNumber: _accessCardController.text.isEmpty
          ? null
          : _accessCardController.text,
    );

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _performCheckOut(BuildContext context) async {
    final provider = context.read<GateAccessCheckInProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    final success = await provider.performCheckOut(
      guardId: user.uid,
      guardName: user.fullName,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      returnIdCard: _returnIdCard,
      returnAccessCard: _returnAccessCard,
    );

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
