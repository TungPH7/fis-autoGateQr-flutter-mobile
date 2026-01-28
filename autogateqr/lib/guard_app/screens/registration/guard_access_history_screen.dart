import 'package:flutter/material.dart';
import '../../../models/visitor_access_log_model.dart';
import '../../../services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';

class GuardAccessHistoryScreen extends StatefulWidget {
  const GuardAccessHistoryScreen({super.key});

  @override
  State<GuardAccessHistoryScreen> createState() =>
      _GuardAccessHistoryScreenState();
}

class _GuardAccessHistoryScreenState extends State<GuardAccessHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'all'; // 'all', 'check_in', 'check_out', '7days'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử ra/vào'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Check-in', 'check_in'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Check-out', 'check_out'),
                  const SizedBox(width: 8),
                  _buildFilterChip('7 ngày qua', '7days'),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.guardPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.guardPrimary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.guardPrimary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLogsList() {
    Stream<List<VisitorAccessLogModel>> stream;

    switch (_selectedFilter) {
      case 'check_in':
        stream = _firestoreService.getVisitorAccessLogsByType('check_in');
        break;
      case 'check_out':
        stream = _firestoreService.getVisitorAccessLogsByType('check_out');
        break;
      case '7days':
        stream = _firestoreService.getVisitorAccessLogsLastDays(7);
        break;
      case 'all':
      default:
        stream = _firestoreService.getAllVisitorAccessLogs();
        break;
    }

    return StreamBuilder<List<VisitorAccessLogModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}'),
              ],
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử ra/vào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log);
            },
          ),
        );
      },
    );
  }

  Widget _buildLogCard(VisitorAccessLogModel log) {
    final isCheckIn = log.isCheckIn;
    final color = isCheckIn ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showLogDetail(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCheckIn ? Icons.login : Icons.logout,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.visitorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.visitorPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Type badge and time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.typeDisplay,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.timeDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        log.dateDisplay,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Info rows
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.category_outlined,
                      log.visitorTypeDisplay,
                    ),
                  ),
                  if (log.purpose != null)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.description_outlined,
                        log.purpose!,
                      ),
                    ),
                ],
              ),

              // Additional info
              if (log.addressOrCompany != null) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.business_outlined,
                  log.addressOrCompany!,
                ),
              ],

              // Badges
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (log.idCardHeldByGuard)
                    _buildBadge(
                      Icons.credit_card,
                      'Giữ CCCD',
                      Colors.orange,
                    ),
                  if (log.accessCardNumber != null)
                    _buildBadge(
                      Icons.badge,
                      'Thẻ: ${log.accessCardNumber}',
                      Colors.blue,
                    ),
                  if (log.guardName != null)
                    _buildBadge(
                      Icons.security,
                      log.guardName!,
                      Colors.purple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetail(VisitorAccessLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (log.isCheckIn ? Colors.green : Colors.orange)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.isCheckIn ? Icons.login : Icons.logout,
                      color: log.isCheckIn ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.visitorName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          log.typeDisplay,
                          style: TextStyle(
                            color: log.isCheckIn ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              _buildDetailSection('Thông tin khách', [
                _buildDetailRow('Họ tên', log.visitorName),
                _buildDetailRow('Số điện thoại', log.visitorPhone),
                if (log.visitorIdCard != null)
                  _buildDetailRow('CCCD/CMND', log.visitorIdCard!),
                _buildDetailRow('Loại', log.visitorTypeDisplay),
                if (log.addressOrCompany != null)
                  _buildDetailRow('Địa chỉ/Công ty', log.addressOrCompany!),
              ]),
              const SizedBox(height: 16),

              _buildDetailSection('Thời gian', [
                _buildDetailRow('Loại', log.typeDisplay),
                _buildDetailRow('Thời gian', log.dateTimeDisplay),
                if (log.purpose != null)
                  _buildDetailRow('Mục đích', log.purpose!),
              ]),
              const SizedBox(height: 16),

              if (log.idCardHeldByGuard || log.accessCardNumber != null)
                _buildDetailSection('Thông tin thêm', [
                  if (log.idCardHeldByGuard)
                    _buildDetailRow('Giữ CCCD', 'Bảo vệ đang giữ CCCD'),
                  if (log.accessCardNumber != null)
                    _buildDetailRow('Thẻ ra vào', log.accessCardNumber!),
                ]),
              if (log.idCardHeldByGuard || log.accessCardNumber != null)
                const SizedBox(height: 16),

              _buildDetailSection('Bảo vệ xử lý', [
                _buildDetailRow('Bảo vệ', log.guardName ?? 'N/A'),
                if (log.gateName != null) _buildDetailRow('Cổng', log.gateName!),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
