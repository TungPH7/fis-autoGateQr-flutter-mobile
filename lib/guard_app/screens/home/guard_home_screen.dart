import 'package:autogateqr/guard_app/screens/registration/guard_waiting_checkout_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/gate_access_registration_model.dart';
import '../../../models/visitor_access_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/check_in_provider.dart';
import '../../../services/firestore_service.dart';
import '../history/guard_visitor_access_history_screen.dart';
import '../history/visitor_access_log_detail_screen.dart';
import '../profile/guard_profile_detail_screen.dart';
import '../registration/guard_manual_registration_screen.dart';
import '../registration/guard_registration_list_screen.dart';
import '../registration/guard_today_registration_screen.dart';
import '../registration/guard_visiting_list_screen.dart';
import '../scanner/qr_scanner_screen.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    final checkInProvider = context.read<CheckInProvider>();
    checkInProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            onNavigateToProfile: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          const _AccessHistoryTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );
        },
        backgroundColor: AppColors.guardPrimary,
        child: const Icon(Icons.qr_code_scanner, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final VoidCallback onNavigateToProfile;

  const _DashboardTab({required this.onNavigateToProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        backgroundColor: AppColors.guardPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Cá nhân',
            onPressed: onNavigateToProfile,
          ),
        ],
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              provider.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildTotalRegistrationsStatCard(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildVisitingStatCard(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCheckoutStatCard(context)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  const Text(
                    'Thao tác nhanh',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.qr_code_scanner,
                          title: 'Quét QR',
                          subtitle: 'Check-in/out',
                          color: AppColors.guardPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRScannerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.person_add,
                          title: 'Đăng ký',
                          subtitle: 'Khách walk-in',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GuardManualRegistrationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.today,
                          title: 'Đăng ký hôm nay',
                          subtitle: 'Xem đăng ký trong ngày',
                          color: AppColors.info,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GuardTodayRegistrationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.directions_walk,
                          title: 'Danh sách đăng ký',
                          subtitle: 'Tất cả đăng ký vào/ra cổng',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GuardRegistrationListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // History card
                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.history,
                          title: 'Lịch sử Check-in/out',
                          subtitle: 'Xem lịch sử ra vào khách',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GuardVisitorAccessHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      // Waiting checkout card
                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildActionCard(
                          context,
                          icon: Icons.hourglass_empty,
                          title: 'Khách chưa checkout',
                          subtitle: 'Khách chưa ra khỏi cổng',
                          color: AppColors.warning,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GuardWaitingCheckoutListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent access logs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ra/vào gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GuardVisitorAccessHistoryScreen(),
                            ),
                          );
                        },
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent visitor access logs (5 records)
                  _buildRecentVisitorLogs(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Card hiển thị tổng số đăng ký
  Widget _buildTotalRegistrationsStatCard(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<GateAccessRegistrationModel>>(
      stream: firestoreService.getAllGateAccessRegistrations(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return _buildStatCard(
          icon: Icons.people,
          title: 'Tổng số đăng ký',
          value: count.toString(),
          color: AppColors.checkInColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GuardRegistrationListScreen(),
              ),
            );
          },
        );
      },
    );
  }

  // Card hiển thị số lượng khách đang viếng thăm với StreamBuilder
  Widget _buildVisitingStatCard(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<GateAccessRegistrationModel>>(
      stream: firestoreService.getVisitorsCurrentlyInside(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return _buildStatCard(
          icon: Icons.directions_walk,
          title: 'Đang viếng thăm',
          value: count.toString(),
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GuardVisitingListScreen(),
              ),
            );
          },
        );
      },
    );
  }

  // Card hiển thị số lượng checkout
  Widget _buildCheckoutStatCard(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<VisitorAccessLogModel>>(
      stream: firestoreService.getVisitorAccessLogsByType('check_out'),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return _buildStatCard(
          icon: Icons.logout,
          title: 'Check-out',
          value: count.toString(),
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GuardVisitorAccessHistoryScreen(
                  initialFilter: 'check_out',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recent visitor access logs widget (5 records)
  Widget _buildRecentVisitorLogs() {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<VisitorAccessLogModel>>(
      stream: firestoreService.getRecentVisitorAccessLogs(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Lỗi: ${snapshot.error}')),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có lịch sử ra/vào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: logs
              .map((log) => _buildVisitorLogCardSmall(context, log))
              .toList(),
        );
      },
    );
  }

  Widget _buildVisitorLogCardSmall(
    BuildContext context,
    VisitorAccessLogModel log,
  ) {
    final isCheckIn = log.isCheckIn;
    final color = isCheckIn ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitorAccessLogDetailScreen(log: log),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(isCheckIn ? Icons.login : Icons.logout, color: color),
        ),
        title: Text(
          log.visitorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${log.visitorPhone} - ${log.dateTimeDisplay}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.typeDisplay,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessHistoryTab extends StatelessWidget {
  const _AccessHistoryTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử ra/vào'),
        backgroundColor: AppColors.guardPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Xem chi tiết',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuardVisitorAccessHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<VisitorAccessLogModel>>(
        stream: firestoreService.getTodayVisitorAccessLogs(),
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
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lịch sử check-in/out hôm nay',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GuardVisitorAccessHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Xem tất cả lịch sử'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.guardPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.guardPrimary.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Check-in',
                      logs.where((l) => l.isCheckIn).length.toString(),
                      Colors.green,
                    ),
                    _buildSummaryItem(
                      'Check-out',
                      logs.where((l) => l.isCheckOut).length.toString(),
                      Colors.orange,
                    ),
                    _buildSummaryItem(
                      'Tổng',
                      logs.length.toString(),
                      AppColors.guardPrimary,
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildVisitorLogCard(log);
                  },
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildVisitorLogCard(VisitorAccessLogModel log) {
    final isCheckIn = log.isCheckIn;
    final color = isCheckIn ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    log.visitorPhone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (log.purpose != null)
                    Text(
                      log.purpose!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.typeDisplay,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.timeDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  log.dateDisplay,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AppColors.guardPrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Không có thông tin'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.guardPrimary,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.guardPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Bảo vệ',
                    style: TextStyle(
                      color: AppColors.guardPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Settings cards
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Thông tin cá nhân'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GuardProfileDetailScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Cài đặt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to settings
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Trợ giúp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to help
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc muốn đăng xuất ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Huỷ'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      context.read<CheckInProvider>().clear();
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
