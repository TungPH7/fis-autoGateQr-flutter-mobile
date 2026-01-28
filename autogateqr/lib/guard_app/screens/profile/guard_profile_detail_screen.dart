import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class GuardProfileDetailScreen extends StatelessWidget {
  const GuardProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(
              child: Text('Không có thông tin người dùng'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar section
                _buildAvatarSection(user.fullName, user.photoUrl),
                const SizedBox(height: 24),

                // Personal Info Card
                _buildSectionCard(
                  title: 'Thông tin cơ bản',
                  icon: Icons.person,
                  children: [
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Họ và tên',
                      value: user.fullName,
                    ),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      value: user.phone,
                    ),
                    if (user.employeeId != null)
                      _buildInfoTile(
                        icon: Icons.numbers,
                        label: 'Mã nhân viên',
                        value: user.employeeId!,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Info Card
                _buildSectionCard(
                  title: 'Thông tin công việc',
                  icon: Icons.work,
                  children: [
                    _buildInfoTile(
                      icon: Icons.security,
                      label: 'Vai trò',
                      value: 'Bảo vệ',
                      valueColor: AppColors.guardPrimary,
                    ),
                    _buildInfoTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Trạng thái',
                      value: _getStatusText(user.status),
                      valueColor: _getStatusColor(user.status),
                    ),
                    if (user.department != null)
                      _buildInfoTile(
                        icon: Icons.business_outlined,
                        label: 'Phòng ban',
                        value: user.department!,
                      ),
                    if (user.company != null)
                      _buildInfoTile(
                        icon: Icons.apartment_outlined,
                        label: 'Công ty',
                        value: user.company!,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Account Info Card
                _buildSectionCard(
                  title: 'Thông tin tài khoản',
                  icon: Icons.account_circle,
                  children: [
                    _buildInfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Ngày tạo tài khoản',
                      value: Helpers.formatDateTime(user.createdAt),
                    ),
                    if (user.lastLogin != null)
                      _buildInfoTile(
                        icon: Icons.login,
                        label: 'Đăng nhập gần nhất',
                        value: Helpers.formatDateTime(user.lastLogin!),
                      ),
                    if (user.validFrom != null)
                      _buildInfoTile(
                        icon: Icons.event_available_outlined,
                        label: 'Hiệu lực từ',
                        value: Helpers.formatDate(user.validFrom!),
                      ),
                    if (user.validTo != null)
                      _buildInfoTile(
                        icon: Icons.event_busy_outlined,
                        label: 'Hiệu lực đến',
                        value: Helpers.formatDate(user.validTo!),
                        valueColor: user.validTo!.isBefore(DateTime.now())
                            ? Colors.red
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Liên hệ quản trị viên nếu cần cập nhật thông tin cá nhân.',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(String fullName, String? photoUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: AppColors.guardPrimary,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.guardPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: AppColors.guardPrimary,
              ),
              SizedBox(width: 6),
              Text(
                'Nhân viên bảo vệ',
                style: TextStyle(
                  color: AppColors.guardPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  child: Icon(
                    icon,
                    color: AppColors.guardPrimary,
                    size: 20,
                  ),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
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
                    fontSize: 15,
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

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'suspended':
        return 'Tạm ngưng';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
