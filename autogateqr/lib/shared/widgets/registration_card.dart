import 'package:flutter/material.dart';
import '../../models/registration_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import 'status_badge.dart';

class RegistrationCard extends StatelessWidget {
  final RegistrationModel registration;
  final VoidCallback? onTap;
  final VoidCallback? onShowQR;

  const RegistrationCard({
    super.key,
    required this.registration,
    this.onTap,
    this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Plate number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        registration.plateNumber ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: registration.status),
                ],
              ),
              const SizedBox(height: 12),

              // Company
              if (registration.companyName != null) ...[
                _buildInfoRow(
                  Icons.business,
                  'Công ty',
                  registration.companyName!,
                ),
                const SizedBox(height: 8),
              ],

              // Driver
              _buildInfoRow(
                Icons.person,
                'Tài xế',
                registration.driverInfo.name,
              ),
              const SizedBox(height: 8),

              // Expected date
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày dự kiến',
                Helpers.formatDate(registration.expectedDate),
              ),
              const SizedBox(height: 8),

              // Purpose
              _buildInfoRow(
                Icons.description,
                'Mục đích',
                registration.visitPurpose,
              ),

              // QR Button for approved registrations
              if (registration.isApproved && registration.hasValidQR) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onShowQR,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Xem mã QR'),
                  ),
                ),
              ],

              // Rejection reason
              if (registration.isRejected && registration.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lý do từ chối: ${registration.rejectionReason}',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}