import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../services/firestore_service.dart';
import 'guard_registration_detail_screen.dart';

class GuardVisitingListScreen extends StatefulWidget {
  const GuardVisitingListScreen({super.key});

  @override
  State<GuardVisitingListScreen> createState() =>
      _GuardVisitingListScreenState();
}

class _GuardVisitingListScreenState extends State<GuardVisitingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<GateAccessRegistrationModel>>(
        stream: _firestoreService.getVisitorsCurrentlyInside(),
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

          final visitors = snapshot.data ?? [];

          if (visitors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có khách đang viếng thăm',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Danh sách này hiển thị những người đã check-in\nvà chưa check-out',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${visitors.length} khách đang viếng thăm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'Đã check-in và chưa check-out',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final visitor = visitors[index];
                      return _buildVisitorCard(visitor);
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

  Widget _buildVisitorCard(GateAccessRegistrationModel visitor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuardRegistrationDetailScreen(registration: visitor),
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
                    backgroundColor: Colors.green,
                    child: Icon(
                      _getVisitorTypeIcon(visitor.visitorType),
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
                          visitor.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visitor.phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đang viếng thăm',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                      visitor.visitorTypeDisplay,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.description_outlined,
                      visitor.purpose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Check-in time
              if (visitor.actualCheckInTime != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.login, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Check-in: ${Helpers.formatDateTime(visitor.actualCheckInTime!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Additional badges
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Giữ CCCD badge
                  if (visitor.idCardHeldByGuard)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 14,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Giữ CCCD',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Thẻ ra vào badge
                  if (visitor.accessCardIssued)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                            'Thẻ: ${visitor.accessCardNumber ?? 'N/A'}',
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
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
