import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/gate_access_provider.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../core/theme/app_colors.dart';
import 'gate_access_detail_screen.dart';

class GateAccessListScreen extends StatelessWidget {
  const GateAccessListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký ra/vào'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white,
            indicatorColor: AppColors.primary,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
            ],
          ),
        ),
        body: Consumer<GateAccessProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _RegistrationList(
                  registrations: provider.allRegistrations,
                  emptyMessage: 'Bạn chưa có đăng ký nào',
                ),
                _RegistrationList(
                  registrations: provider.pendingRegistrations,
                  emptyMessage: 'Không có đăng ký chờ duyệt',
                ),
                _RegistrationList(
                  registrations: provider.approvedRegistrations,
                  emptyMessage: 'Không có đăng ký đã duyệt',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/employee/gate-access/create');
          },
          icon: const Icon(Icons.add),
          label: const Text('Tạo mới'),
        ),
      ),
    );
  }
}

class _RegistrationList extends StatelessWidget {
  final List<GateAccessRegistrationModel> registrations;
  final String emptyMessage;

  const _RegistrationList({
    required this.registrations,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GateAccessProvider>().refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: registrations.length,
        itemBuilder: (context, index) {
          return _RegistrationCard(registration: registrations[index]);
        },
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final GateAccessRegistrationModel registration;

  const _RegistrationCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GateAccessDetailScreen(registration: registration),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildStatusBadge(),
                  _buildVisitorTypeBadge(),
                  Text(
                    registration.expectedDateDisplay,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAccessTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                registration.purpose,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (registration.visitDepartment != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  registration.visitDepartment!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    registration.expectedTimeDisplay,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (registration.hasValidQR)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'QR sẵn sàng',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (registration.status) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
      case 'expired':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        icon = Icons.timer_off;
        break;
      case 'used':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        icon = Icons.block;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            registration.statusDisplay,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorTypeBadge() {
    Color color;
    IconData icon;

    switch (registration.visitorType) {
      case 'employee':
        color = Colors.blue;
        icon = Icons.badge;
        break;
      case 'contractor':
        color = Colors.purple;
        icon = Icons.engineering;
        break;
      default:
        color = Colors.teal;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            registration.visitorTypeDisplay,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTypeIcon() {
    IconData icon;
    Color color;

    switch (registration.accessType) {
      case 'entry':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'exit':
        icon = Icons.logout;
        color = Colors.red;
        break;
      default:
        icon = Icons.swap_horiz;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
