import 'package:flutter/material.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import 'guard_registration_detail_screen.dart';

class GuardTodayRegistrationScreen extends StatefulWidget {
  const GuardTodayRegistrationScreen({super.key});

  @override
  State<GuardTodayRegistrationScreen> createState() =>
      _GuardTodayRegistrationScreenState();
}

class _GuardTodayRegistrationScreenState
    extends State<GuardTodayRegistrationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GateAccessRegistrationModel> _filterRegistrations(
      List<GateAccessRegistrationModel> registrations) {
    if (_searchQuery.isEmpty) return registrations;

    final query = _searchQuery.toLowerCase();
    return registrations.where((reg) {
      return reg.fullName.toLowerCase().contains(query) ||
          reg.phone.contains(query) ||
          (reg.idCard?.contains(query) ?? false) ||
          reg.purpose.toLowerCase().contains(query) ||
          (reg.vehiclePlate?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký hôm nay'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search box - outside StreamBuilder to prevent keyboard issues
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT, CCCD, biển số...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.guardPrimary),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // StreamBuilder only wraps the data-dependent parts
          Expanded(
            child: StreamBuilder<List<GateAccessRegistrationModel>>(
              stream: _firestoreService.getTodayCreatedRegistrations(),
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

                final allRegistrations = snapshot.data ?? [];
                final registrations = _filterRegistrations(allRegistrations);

                return Column(
                  children: [
                    // Header with count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppColors.guardPrimary.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.guardPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.today,
                              color: AppColors.guardPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _searchQuery.isEmpty
                                    ? '${allRegistrations.length} đăng ký hôm nay'
                                    : '${registrations.length}/${allRegistrations.length} kết quả',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.guardPrimary,
                                ),
                              ),
                              Text(
                                'Ngày ${Helpers.formatDate(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.guardPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // List or empty state
                    Expanded(
                      child: allRegistrations.isEmpty
                          ? _buildEmptyState()
                          : registrations.isEmpty
                              ? _buildNoSearchResultState()
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    setState(() {});
                                  },
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: registrations.length,
                                    itemBuilder: (context, index) {
                                      final registration = registrations[index];
                                      return _buildRegistrationCard(registration);
                                    },
                                  ),
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có đăng ký nào hôm nay',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách này hiển thị các đăng ký\nđược tạo trong ngày hôm nay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(GateAccessRegistrationModel registration) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuardRegistrationDetailScreen(
                registration: registration,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getVisitorTypeColor(registration.visitorType),
                    child: Icon(
                      _getVisitorTypeIcon(registration.visitorType),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          registration.phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(registration.status),
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
                      registration.visitorTypeDisplay,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.swap_horiz,
                      registration.accessTypeDisplay,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today_outlined,
                      registration.expectedDateDisplay,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      registration.expectedTimeDisplay,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoItem(
                Icons.description_outlined,
                registration.purpose,
              ),

              // Vehicle info if exists
              if (registration.hasVehicle) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  registration.vehicleType == 'car'
                      ? Icons.directions_car
                      : Icons.two_wheeler,
                  '${registration.vehicleTypeDisplay} - ${registration.vehiclePlate}',
                ),
              ],

              // Status badges row
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Source info
                  if (registration.isRegisteredByGuard)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Đăng ký bởi bảo vệ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Giữ CCCD badge
                  if (registration.idCardHeldByGuard)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'Giữ CCCD',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Thẻ ra vào badge
                  if (registration.accessCardIssued)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Thẻ: ${registration.accessCardNumber ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Đang viếng thăm badge
                  if (registration.isCurrentlyInside)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_walk, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Đang viếng thăm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case 'approved':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Đã duyệt';
        break;
      case 'rejected':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = 'Từ chối';
        break;
      case 'used':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = 'Đã sử dụng';
        break;
      case 'expired':
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = 'Hết hạn';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getVisitorTypeIcon(String type) {
    switch (type) {
      case 'employee':
        return Icons.badge;
      case 'contractor':
        return Icons.engineering;
      case 'visitor':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}
