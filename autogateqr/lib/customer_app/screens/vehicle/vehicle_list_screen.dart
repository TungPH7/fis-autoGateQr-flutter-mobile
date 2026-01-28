import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../shared/widgets/vehicle_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/helpers.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách xe'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, _) {
          if (provider.vehicles.isEmpty) {
            return const EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Chưa có xe nào',
              subtitle: 'Nhấn nút bên dưới để thêm xe mới',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled by stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = provider.vehicles[index];
                return VehicleCard(
                  vehicle: vehicle,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/customer/vehicles/detail',
                      arguments: vehicle,
                    );
                  },
                  onEdit: () {
                    Navigator.pushNamed(
                      context,
                      '/customer/vehicles/edit',
                      arguments: vehicle,
                    );
                  },
                  onDelete: () async {
                    final confirm = await Helpers.showConfirmDialog(
                      context,
                      title: 'Xóa xe',
                      message: 'Bạn có chắc chắn muốn xóa xe ${vehicle.plateNumber}?',
                      confirmText: 'Xóa',
                      isDanger: true,
                    );

                    if (confirm == true) {
                      final success = await provider.deleteVehicle(vehicle.id);
                      if (success && context.mounted) {
                        Helpers.showSuccessSnackBar(context, 'Đã xóa xe');
                      } else if (provider.errorMessage != null && context.mounted) {
                        Helpers.showErrorSnackBar(context, provider.errorMessage!);
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}