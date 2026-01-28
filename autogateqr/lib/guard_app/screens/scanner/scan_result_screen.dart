import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/check_in_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _temperatureController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin người dùng'),
        backgroundColor: AppColors.guardPrimary,
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          final user = provider.scannedUser;

          if (user == null) {
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

                // User info card
                _buildUserInfoCard(provider),
                const SizedBox(height: 16),

                // Last access info
                if (provider.lastUserAccessLog != null) ...[
                  _buildLastAccessCard(provider),
                  const SizedBox(height: 16),
                ],

                // Gate selection
                _buildGateSelection(provider),
                const SizedBox(height: 16),

                // Additional info for check-in
                if (provider.canCheckIn) ...[
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: 16),
                ],

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

  Widget _buildStatusCard(CheckInProvider provider) {
    final isInside = provider.isUserInside;
    final canCheckIn = provider.canCheckIn;
    final canCheckOut = provider.canCheckOut;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (canCheckIn) {
      statusColor = AppColors.success;
      statusIcon = Icons.login;
      statusTitle = 'Sẵn sàng Check-in';
      statusSubtitle = provider.scannedUser?.fullName ?? '';
    } else if (canCheckOut) {
      statusColor = AppColors.warning;
      statusIcon = Icons.logout;
      statusTitle = 'Đang ở trong nhà máy, sẵn sàng Check-out';
      statusSubtitle = provider.scannedUser?.fullName ?? '';
    } else {
      statusColor = AppColors.info;
      statusIcon = Icons.info;
      statusTitle = isInside ? 'Đang ở trong nhà máy' : 'Đang ở ngoài nhà máy';
      statusSubtitle = provider.getStatusText();
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

  Widget _buildUserInfoCard(CheckInProvider provider) {
    final user = provider.scannedUser!;

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
                  'Thong tin nguoi dung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isContractor
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.userTypeDisplay,
                    style: TextStyle(
                      color: user.isContractor ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Avatar and name
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.guardPrimary.withValues(alpha: 0.1),
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.guardPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ma NV: ${user.displayId}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _buildInfoRow(
              Icons.business,
              user.isContractor ? 'Cong ty' : 'Phong ban',
              user.displayDepartmentOrCompany,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'SDT', user.phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', user.email),

            // Validity period for contractors
            if (user.isContractor && user.validTo != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.event,
                'Hieu luc den',
                '${user.validTo!.day}/${user.validTo!.month}/${user.validTo!.year}',
                valueColor: user.isValidPeriod ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastAccessCard(CheckInProvider provider) {
    final lastLog = provider.lastUserAccessLog!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lich su gan nhat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lastLog.isCheckIn
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    lastLog.isCheckIn ? Icons.login : Icons.logout,
                    color: lastLog.isCheckIn ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastLog.typeDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lastLog.isCheckIn ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'Cong: ${lastLog.gateName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastLog.timeDisplay,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lastLog.dateDisplay,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateSelection(CheckInProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chon cong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (provider.gates.isEmpty)
              const Text(
                'Khong co cong nao',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.gates.map((gate) {
                  final isSelected = provider.selectedGate?.id == gate.id;
                  return ChoiceChip(
                    label: Text(gate.gateName),
                    selected: isSelected,
                    onSelected: (_) => provider.selectGate(gate),
                    selectedColor: AppColors.guardPrimary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.guardPrimary : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thong tin bo sung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Temperature
            TextField(
              controller: _temperatureController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Nhiet do (tuy chon)',
                hintText: '36.5',
                prefixIcon: Icon(Icons.thermostat),
                suffixText: '°C',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chu (tuy chon)',
                hintText: 'Ghi chu them...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(CheckInProvider provider) {
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

  Widget _buildActionButtons(CheckInProvider provider) {
    return Column(
      children: [
        if (provider.canCheckIn)
          CustomButton(
            text: 'Check-in',
            onPressed: () => _performCheckIn(context),
            isLoading: provider.isProcessing,
            backgroundColor: AppColors.checkInColor,
            icon: Icons.login,
            width: double.infinity,
          ),

        if (provider.canCheckOut)
          CustomButton(
            text: 'Check-out',
            onPressed: () => _performCheckOut(context),
            isLoading: provider.isProcessing,
            backgroundColor: AppColors.checkOutColor,
            icon: Icons.logout,
            width: double.infinity,
          ),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Quet lai',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performCheckIn(BuildContext context) async {
    final checkInProvider = context.read<CheckInProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    double? temperature;
    if (_temperatureController.text.isNotEmpty) {
      temperature = double.tryParse(_temperatureController.text);
    }

    final success = await checkInProvider.performCheckIn(
      guardId: user.uid,
      guardName: user.fullName,
      temperature: temperature,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _performCheckOut(BuildContext context) async {
    final checkInProvider = context.read<CheckInProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    final success = await checkInProvider.performCheckOut(
      guardId: user.uid,
      guardName: user.fullName,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
