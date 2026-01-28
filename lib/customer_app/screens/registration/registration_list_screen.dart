import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../models/registration_model.dart';
import '../../../shared/widgets/registration_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/qr_code_widget.dart';

class RegistrationListScreen extends StatefulWidget {
  const RegistrationListScreen({super.key});

  @override
  State<RegistrationListScreen> createState() => _RegistrationListScreenState();
}

class _RegistrationListScreenState extends State<RegistrationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQRDialog(RegistrationModel registration) {
    final qrData = context.read<RegistrationProvider>().getQRDataForDisplay(registration);
    if (qrData == null) return;

    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        data: qrData,
        title: 'Mã QR đăng ký',
        plateNumber: registration.plateNumber,
        expiresAt: registration.qrExpiresAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký ra/vào'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
          ],
        ),
      ),
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRegistrationList(provider.registrations),
              _buildRegistrationList(provider.pendingRegistrations),
              _buildRegistrationList(provider.approvedRegistrations),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRegistrationList(List<RegistrationModel> registrations) {
    if (registrations.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Chưa có đăng ký nào',
        subtitle: 'Nhấn nút bên dưới để tạo đăng ký mới',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by stream
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: registrations.length,
        itemBuilder: (context, index) {
          final registration = registrations[index];
          return RegistrationCard(
            registration: registration,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/customer/registrations/detail',
                arguments: registration,
              );
            },
            onShowQR: registration.isApproved && registration.hasValidQR
                ? () => _showQRDialog(registration)
                : null,
          );
        },
      ),
    );
  }
}
