import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vehicle icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getVehicleColor(
                    vehicle.vehicleType,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVehicleIcon(vehicle.vehicleType),
                  color: _getVehicleColor(vehicle.vehicleType),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Vehicle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      VehicleModel.getVehicleTypeName(vehicle.vehicleType),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.driverName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Xóa',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'car':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      case 'container':
        return Icons.rv_hookup;
      case 'motorcycle':
        return Icons.two_wheeler;
      default:
        return Icons.directions_car;
    }
  }

  Color _getVehicleColor(String type) {
    switch (type) {
      case 'car':
        return Colors.blue;
      case 'truck':
        return Colors.orange;
      case 'container':
        return Colors.brown;
      case 'motorcycle':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class VehicleSelectCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  const VehicleSelectCard({
    super.key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VehicleCard(vehicle: vehicle, isSelected: isSelected, onTap: onTap);
  }
}
