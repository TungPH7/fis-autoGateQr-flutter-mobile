import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
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
                // Avatar and name
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (user.companyName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.companyName!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info card
                Card(
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.phone,
                        title: 'Số điện thoại',
                        subtitle: user.phone,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.badge,
                        title: 'Vai trò',
                        subtitle: _getRoleName(user.role),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.calendar_today,
                        title: 'Ngày tạo',
                        subtitle: Helpers.formatDate(user.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Settings card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Chỉnh sửa thông tin'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to edit profile
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Đổi mật khẩu'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to change password
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Cài đặt'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to settings
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logout button
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () async {
                      final confirm = await Helpers.showConfirmDialog(
                        context,
                        title: 'Đăng xuất',
                        message: 'Bạn có chắc chắn muốn đăng xuất?',
                        confirmText: 'Đăng xuất',
                        isDanger: true,
                      );

                      if (confirm == true && context.mounted) {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // App version
                const Text(
                  'AutoGate QR v1.0.0',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'customer':
        return 'Khách hàng';
      case 'admin':
        return 'Quản trị viên';
      case 'guard':
        return 'Bảo vệ';
      default:
        return role;
    }
  }
}