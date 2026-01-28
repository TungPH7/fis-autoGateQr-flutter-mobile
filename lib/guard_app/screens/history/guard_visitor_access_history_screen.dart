import 'package:flutter/material.dart';
import '../../../models/visitor_access_log_model.dart';
import '../../../services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import 'visitor_access_log_detail_screen.dart';

class GuardVisitorAccessHistoryScreen extends StatefulWidget {
  final String? initialFilter;

  const GuardVisitorAccessHistoryScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<GuardVisitorAccessHistoryScreen> createState() =>
      _GuardVisitorAccessHistoryScreenState();
}

class _GuardVisitorAccessHistoryScreenState
    extends State<GuardVisitorAccessHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedFilter; // 'all', 'today', 'check_in', 'check_out'
  String _searchQuery = '';

  final List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'today', 'label': 'Hôm nay'},
    {'value': 'check_in', 'label': 'Check-in'},
    {'value': 'check_out', 'label': 'Check-out'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<VisitorAccessLogModel>> _getFilteredStream() {
    switch (_selectedFilter) {
      case 'today':
        return _firestoreService.getTodayVisitorAccessLogs();
      case 'check_in':
        return _firestoreService.getVisitorAccessLogsByType('check_in');
      case 'check_out':
        return _firestoreService.getVisitorAccessLogsByType('check_out');
      case 'all':
      default:
        return _firestoreService.getAllVisitorAccessLogs();
    }
  }

  List<VisitorAccessLogModel> _applySearchFilter(List<VisitorAccessLogModel> logs) {
    if (_searchQuery.isEmpty) return logs;

    final query = _searchQuery.toLowerCase();
    return logs.where((log) {
      return log.visitorName.toLowerCase().contains(query) ||
             log.visitorPhone.toLowerCase().contains(query) ||
             (log.visitorIdCard?.toLowerCase().contains(query) ?? false) ||
             (log.purpose?.toLowerCase().contains(query) ?? false) ||
             (log.addressOrCompany?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _navigateToDetail(VisitorAccessLogModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitorAccessLogDetailScreen(log: log),
      ),
    );
  }

  void _showContextMenu(VisitorAccessLogModel log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: log.isCheckIn
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.isCheckIn ? Icons.login : Icons.logout,
                      color: log.isCheckIn ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.visitorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${log.typeDisplay} - ${log.dateTimeDisplay}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // Menu items
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.guardPrimary),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(log);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa lịch sử', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(log);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(VisitorAccessLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn xóa lịch sử này?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khách: ${log.visitorName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${log.typeDisplay} - ${log.dateTimeDisplay}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firestoreService.deleteVisitorAccessLog(log.id);
        if (mounted) {
          Helpers.showSuccessSnackBar(context, 'Đã xóa lịch sử');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showErrorSnackBar(context, 'Lỗi: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Check-in/out'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter and Search section
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
                // Search box and filter icon row
                Row(
                  children: [
                    // Search box
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên, SĐT, CCCD...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.guardPrimary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedFilter != 'all'
                              ? AppColors.guardPrimary
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedFilter != 'all'
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      tooltip: 'Bộ lọc',
                      onSelected: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                      itemBuilder: (context) => _filterOptions.map((option) {
                        final isSelected = _selectedFilter == option['value'];
                        return PopupMenuItem<String>(
                          value: option['value'],
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppColors.guardPrimary
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option['label']!,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.guardPrimary
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Show current filter label if not "all"
                if (_selectedFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.guardPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _filterOptions.firstWhere(
                                  (o) => o['value'] == _selectedFilter,
                                )['label']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.guardPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = 'all';
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.guardPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // List content
          Expanded(
            child: StreamBuilder<List<VisitorAccessLogModel>>(
              stream: _getFilteredStream(),
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

                final allLogs = snapshot.data ?? [];
                final logs = _applySearchFilter(allLogs);

                if (logs.isEmpty) {
                  return _buildEmptyState(
                    _searchQuery.isNotEmpty
                        ? 'Không tìm thấy kết quả cho "$_searchQuery"'
                        : 'Chưa có lịch sử check-in/out',
                  );
                }

                return _buildLogList(logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<VisitorAccessLogModel> logs) {
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
        onTap: () => _navigateToDetail(log),
        onLongPress: () => _showContextMenu(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCheckIn ? Icons.login : Icons.logout,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type badge
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTypeBadge(log.typeDisplay, color),
                            const SizedBox(width: 8),
                            _buildVisitorTypeBadge(log.visitorTypeDisplay),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log.timeDisplay,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        log.dateDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
              _buildInfoRow(Icons.phone, log.visitorPhone),
              if (log.visitorIdCard != null)
                _buildInfoRow(Icons.credit_card, 'CCCD: ${log.visitorIdCard}'),
              if (log.purpose != null)
                _buildInfoRow(Icons.description, log.purpose!),
              if (log.addressOrCompany != null)
                _buildInfoRow(Icons.business, log.addressOrCompany!),
              if (log.gateName != null)
                _buildInfoRow(Icons.door_front_door, 'Cổng: ${log.gateName}'),
              if (log.guardName != null)
                _buildInfoRow(Icons.security, 'Bảo vệ: ${log.guardName}'),

              // Badges row
              if (log.idCardHeldByGuard || log.accessCardNumber != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (log.idCardHeldByGuard)
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
                    if (log.accessCardNumber != null)
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
                              'Thẻ: ${log.accessCardNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVisitorTypeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.purple,
        ),
      ),
    );
  }
}
