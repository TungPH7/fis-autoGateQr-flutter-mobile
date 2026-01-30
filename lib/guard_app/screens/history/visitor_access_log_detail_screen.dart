import 'package:autogateqr/core/utils/helpers.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/visitor_access_log_model.dart';

class VisitorAccessLogDetailScreen extends StatelessWidget {
  final VisitorAccessLogModel log;

  const VisitorAccessLogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = log.isCheckIn;
    final color = isCheckIn ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch sử'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Card(
              color: Helpers.getCardBackgroundFromStatus(
                isCheckIn ? Colors.green : Colors.orange,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheckIn ? Icons.login : Icons.logout,
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.typeDisplay,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.dateTimeDisplay,
                            style: TextStyle(
                              fontSize: 14,
                              color: color.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visitor Info Card
            _buildSectionCard(
              title: 'Thông tin khách',
              icon: Icons.person,
              children: [
                _buildInfoRow('Họ tên', log.visitorName),
                _buildInfoRow('Số điện thoại', log.visitorPhone),
                if (log.visitorIdCard != null)
                  _buildInfoRow('CCCD/CMND', log.visitorIdCard!),
                _buildInfoRow('Loại', log.visitorTypeDisplay),
                if (log.addressOrCompany != null)
                  _buildInfoRow('Địa chỉ/Công ty', log.addressOrCompany!),
              ],
            ),
            const SizedBox(height: 16),

            // Visit Info Card
            if (log.purpose != null || log.gateName != null)
              _buildSectionCard(
                title: 'Thông tin ra/vào',
                icon: Icons.info_outline,
                children: [
                  if (log.purpose != null)
                    _buildInfoRow('Mục đích', log.purpose!),
                  if (log.gateName != null)
                    _buildInfoRow('Cổng', log.gateName!),
                ],
              ),
            if (log.purpose != null || log.gateName != null)
              const SizedBox(height: 16),

            // Guard Info Card
            if (log.guardName != null)
              _buildSectionCard(
                title: 'Bảo vệ xử lý',
                icon: Icons.security,
                children: [_buildInfoRow('Tên bảo vệ', log.guardName!)],
              ),
            if (log.guardName != null) const SizedBox(height: 16),

            // Card/ID Info
            if (log.idCardHeldByGuard || log.accessCardNumber != null)
              _buildSectionCard(
                title: 'Thẻ & Giấy tờ',
                icon: Icons.badge,
                children: [
                  if (log.idCardHeldByGuard)
                    _buildInfoRow(
                      'CCCD/CMND',
                      'Bảo vệ giữ',
                      valueColor: Colors.orange,
                    ),
                  if (log.accessCardNumber != null)
                    _buildInfoRow('Mã thẻ ra vào', log.accessCardNumber!),
                ],
              ),
            if (log.idCardHeldByGuard || log.accessCardNumber != null)
              const SizedBox(height: 16),

            // Note Card
            if (log.note != null)
              _buildSectionCard(
                title: 'Ghi chú',
                icon: Icons.note,
                children: [
                  Text(log.note!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            if (log.note != null) const SizedBox(height: 16),

            // System Info Card
            _buildSectionCard(
              title: 'Thông tin hệ thống',
              icon: Icons.settings,
              children: [
                _buildInfoRow('Mã log', log.id),
                _buildInfoRow('Mã đăng ký', log.registrationId),
              ],
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
            width: 120,
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
