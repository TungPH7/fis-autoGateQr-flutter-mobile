import 'dart:async';

import 'package:autogateqr/services/firestore_service.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/gate_access_registration_model.dart';
import 'guard_registration_detail_screen.dart';

class GuardWaitingCheckoutListScreen extends StatefulWidget {
  final String? initialFilter;

  const GuardWaitingCheckoutListScreen({super.key, this.initialFilter});

  @override
  State<GuardWaitingCheckoutListScreen> createState() {
    return _GuardWaitingCheckoutListScreenState();
  }
}

class _GuardWaitingCheckoutListScreenState
    extends State<GuardWaitingCheckoutListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Timer for real-time duration updates
  Timer? _refreshTimer;

  // Filter States
  bool _onlyToday = false;
  bool? _idCardHeld; // null = both, true = held, false = not held

  @override
  void initState() {
    super.initState();
    // Refresh UI every minute to update "Duration Inside"
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Stream<List<GateAccessRegistrationModel>> _getFilteredStream() {
    return _firestoreService.getVisitorsInsideBase(onlyToday: _onlyToday).map((
      items,
    ) {
      List<GateAccessRegistrationModel> filtered = items;

      if (_idCardHeld != null) {
        filtered = filtered
            .where((e) => e.idCardHeldByGuard == _idCardHeld)
            .toList();
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((e) {
          return e.fullName.toLowerCase().contains(query) ||
              e.phone.contains(query) ||
              (e.vehiclePlate?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Khách chưa checkout'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildActiveFilters(),
          Expanded(
            child: StreamBuilder<List<GateAccessRegistrationModel>>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return VisitorCard(
                      item: items[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GuardRegistrationDetailScreen(
                              registration: items[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.guardPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, SĐT, biển số...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              GestureDetector(
                onTap: _openFilterMenu,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: _hasActiveFilter()
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ),
              if (_hasActiveFilter())
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilter() {
    return _onlyToday || _idCardHeld != null;
  }

  void _openFilterMenu() {
    bool tempOnlyToday = _onlyToday;
    bool? tempIdCardHeld = _idCardHeld;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bộ lọc tìm kiếm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chỉ khách hôm nay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Hiển thị khách vào trong ngày',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: tempOnlyToday,
                        activeColor: AppColors.guardPrimary,
                        onChanged: (value) {
                          setModalState(() => tempOnlyToday = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tình trạng giấy tờ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChoiceChip(
                        label: 'Tất cả',
                        isSelected: tempIdCardHeld == null,
                        onSelected: (_) =>
                            setModalState(() => tempIdCardHeld = null),
                      ),
                      _buildFilterChoiceChip(
                        label: 'Đang giữ CCCD',
                        isSelected: tempIdCardHeld == true,
                        onSelected: (_) =>
                            setModalState(() => tempIdCardHeld = true),
                      ),
                      _buildFilterChoiceChip(
                        label: 'Không giữ CCCD',
                        isSelected: tempIdCardHeld == false,
                        onSelected: (_) =>
                            setModalState(() => tempIdCardHeld = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempOnlyToday = false;
                              tempIdCardHeld = null;
                            });
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.guardPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _onlyToday = tempOnlyToday;
                              _idCardHeld = tempIdCardHeld;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.guardPrimary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.guardPrimary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.guardPrimary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (!_hasActiveFilter()) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_onlyToday)
              _filterChip(
                'Khách hôm nay',
                () => setState(() => _onlyToday = false),
              ),
            if (_idCardHeld != null)
              _filterChip(
                _idCardHeld! ? 'Đang giữ CCCD' : 'Không giữ CCCD',
                () => setState(() => _idCardHeld = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.guardPrimary),
        ),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 14),
        backgroundColor: AppColors.guardPrimary.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_accounts_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Không có khách nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy kết quả cho "$_searchQuery"'
                : 'Hiện không có khách nào đang ở trong cổng',
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilter() || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _onlyToday = false;
                  _idCardHeld = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Xóa tất cả bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Lỗi: $error'),
        ],
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  final GateAccessRegistrationModel item;
  final VoidCallback onTap;

  const VisitorCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.guardPrimary.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      item.nameInitial,
                      style: const TextStyle(
                        color: AppColors.guardPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thời gian trong khu vực: ${item.stayDurationDisplay}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: item.phone,
              ),
              if (item.hasVehicle)
                _InfoRow(
                  icon: item.vehicleType == 'car'
                      ? Icons.directions_car_outlined
                      : Icons.two_wheeler_outlined,
                  label: 'Phương tiện',
                  value: '${item.vehiclePlate} (${item.vehicleTypeDisplay})',
                ),
              _InfoRow(
                icon: Icons.login_outlined,
                label: 'Giờ vào',
                value: item.checkInTimeDisplay,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.idCardHeldByGuard)
                    _IndicatorBadge(
                      icon: Icons.assignment_ind,
                      label: 'Đang giữ CCCD',
                      color: Colors.red,
                    ),
                  if (item.accessCardIssued)
                    _IndicatorBadge(
                      icon: Icons.credit_card,
                      label: 'Đã cấp thẻ: ${item.accessCardNumber}',
                      color: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IndicatorBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
