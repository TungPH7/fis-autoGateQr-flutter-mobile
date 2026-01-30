import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class GuardRegisterScreen extends StatefulWidget {
  const GuardRegisterScreen({super.key});

  @override
  State<GuardRegisterScreen> createState() => _GuardRegisterScreenState();
}

class _GuardRegisterScreenState extends State<GuardRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: AppConstants.roleGuard,
      employeeId: _employeeIdController.text.trim().isNotEmpty
          ? _employeeIdController.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/guard/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản bảo vệ'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.guardPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 40,
                    color: AppColors.guardPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Full name
                CustomTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => Validators.required(value, 'Họ và tên'),
                ),
                const SizedBox(height: 16),

                // Employee ID
                CustomTextField(
                  controller: _employeeIdController,
                  label: 'Mã nhân viên',
                  hint: 'Nhập mã nhân viên bảo vệ',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (value) =>
                      Validators.required(value, 'Mã nhân viên'),
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Nhập email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                // Phone
                CustomTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: 'Nhập số điện thoại',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),

                // Password
                PasswordTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu (ít nhất 6 ký tự)',
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),

                // Confirm password
                PasswordTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 24),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: auth.clearError,
                              color: AppColors.error,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Register button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: 'Đăng ký',
                      onPressed: _handleRegister,
                      isLoading: auth.isLoading,
                      backgroundColor: AppColors.guardPrimary,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.guardPrimary,
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
