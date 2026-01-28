import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gate_access_provider.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../core/theme/app_colors.dart';

class EmployeeAccessHistoryScreen extends StatefulWidget {
  const EmployeeAccessHistoryScreen({super.key});

  @override
  State<EmployeeAccessHistoryScreen> createState() =>
      _EmployeeAccessHistoryScreenState();
}

class _EmployeeAccessHistoryScreenState
    extends State<EmployeeAccessHistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'checked_in', 'checked_out', 'pending'

  final List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'checked_in', 'label': 'Đã vào'},
    {'value': 'checked_out', 'label': 'Đã ra'},
    {'value': 'pending', 'label': 'Chờ duyệt'},
  ];

  List<GateAccessRegistrationModel> _applyFilter(List<GateAccessRegistrationModel> registrations) {
    switch (_selectedFilter) {
      case 'checked_in':
        // Đã check-in nhưng chưa check-out
        return registrations.where((r) => r.hasCheckedIn && !r.hasCheckedOut).toList();
      case 'checked_out':
        // Đã check-out
        return registrations.where((r) => r.hasCheckedOut).toList();
      case 'pending':
        // Chờ duyệt
        return registrations.where((r) => r.isPending).toList();
      case 'all':
      default:
        return registrations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử ra/vào'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthProvider, GateAccessProvider>(
        builder: (context, authProvider, gateAccessProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('Vui lòng đăng nhập'));
          }

          final allRegistrations = gateAccessProvider.allRegistrations;
          // Lọc những registration đã có check-in hoặc check-out
          final registrationsWithHistory = allRegistrations.where((r) =>
            r.hasCheckedIn || r.hasCheckedOut || r.isPending || r.isApproved
          ).toList();

          final filteredRegistrations = _applyFilter(registrationsWithHistory);

          // Tính toán thống kê
          final checkedInCount = allRegistrations.where((r) => r.hasCheckedIn && !r.hasCheckedOut).length;
          final checkedOutCount = allRegistrations.where((r) => r.hasCheckedOut).length;
          final totalCount = allRegistrations.where((r) => r.hasCheckedIn || r.hasCheckedOut).length;

          return Column(
            children: [
              // Filter section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((option) {
                          final isSelected = _selectedFilter == option['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option['label']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = option['value']!;
                                });
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Summary row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Đang trong',
                          checkedInCount.toString(),
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Đã ra',
                          checkedOutCount.toString(),
                          Colors.orange,
                        ),
                        _buildSummaryItem(
                          'Tổng',
                          totalCount.toString(),
                          AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: filteredRegistrations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          gateAccessProvider.refresh();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRegistrations.length,
                          itemBuilder: (context, index) {
                            return _buildRegistrationCard(filteredRegistrations[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Chưa có lịch sử ra/vào'
                : 'Không có kết quả cho bộ lọc này',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(GateAccessRegistrationModel registration) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (registration.hasCheckedOut) {
      statusColor = Colors.blue;
      statusIcon = Icons.logout;
      statusText = 'Đã ra';
    } else if (registration.hasCheckedIn) {
      statusColor = Colors.green;
      statusIcon = Icons.login;
      statusText = 'Đang trong';
    } else if (registration.isApproved) {
      statusColor = Colors.orange;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Đã duyệt';
    } else if (registration.isPending) {
      statusColor = Colors.grey;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Chờ duyệt';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = registration.statusDisplay;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.purpose,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      registration.expectedDateDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      registration.expectedTimeDisplay,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Check-in/out times
            if (registration.hasCheckedIn || registration.hasCheckedOut) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (registration.actualCheckInTime != null)
                    Expanded(
                      child: _buildTimeInfo(
                        'Check-in',
                        registration.actualCheckInTime!,
                        Colors.green,
                        Icons.login,
                      ),
                    ),
                  if (registration.actualCheckInTime != null && registration.actualCheckOutTime != null)
                    const SizedBox(width: 16),
                  if (registration.actualCheckOutTime != null)
                    Expanded(
                      child: _buildTimeInfo(
                        'Check-out',
                        registration.actualCheckOutTime!,
                        Colors.orange,
                        Icons.logout,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, DateTime time, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
