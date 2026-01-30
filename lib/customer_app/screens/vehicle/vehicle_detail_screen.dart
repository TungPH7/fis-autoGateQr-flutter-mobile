import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/vehicle_model.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class VehicleDetailScreen extends StatefulWidget {
  final VehicleModel vehicle;
  final bool isEditMode;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    this.isEditMode = false,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late bool _isEditing;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _plateNumberController;
  late TextEditingController _driverNameController;
  late TextEditingController _driverPhoneController;
  late TextEditingController _driverLicenseController;
  late TextEditingController _brandController;
  late TextEditingController _colorController;
  late String _vehicleType;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditMode;
    _initControllers();
  }

  void _initControllers() {
    _plateNumberController = TextEditingController(
      text: widget.vehicle.plateNumber,
    );
    _driverNameController = TextEditingController(
      text: widget.vehicle.driverName,
    );
    _driverPhoneController = TextEditingController(
      text: widget.vehicle.driverPhone,
    );
    _driverLicenseController = TextEditingController(
      text: widget.vehicle.driverLicense ?? '',
    );
    _brandController = TextEditingController(text: widget.vehicle.brand ?? '');
    _colorController = TextEditingController(text: widget.vehicle.color ?? '');
    _vehicleType = widget.vehicle.vehicleType;
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VehicleProvider>();

    final success = await provider.updateVehicle(widget.vehicle.id, {
      'plateNumber': _plateNumberController.text.trim().toUpperCase(),
      'plateNumberNormalized': _plateNumberController.text
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), ''),
      'vehicleType': _vehicleType,
      'driverName': _driverNameController.text.trim(),
      'driverPhone': _driverPhoneController.text.trim(),
      'brand': _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      'color': _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      'driverLicense': _driverLicenseController.text.trim().isNotEmpty
          ? _driverLicenseController.text.trim()
          : null,
    });

    if (success && mounted) {
      Helpers.showSuccessSnackBar(context, 'Cập nhật thành công');
      setState(() {
        _isEditing = false;
      });
    } else if (provider.errorMessage != null && mounted) {
      Helpers.showErrorSnackBar(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa xe' : 'Chi tiết xe'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _initControllers();
                setState(() {
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildInfoSection('Thông tin xe', Icons.directions_car, [
            _buildInfoRow('Biển số xe', widget.vehicle.plateNumber),
            _buildInfoRow(
              'Loại xe',
              VehicleModel.getVehicleTypeName(widget.vehicle.vehicleType),
            ),
            if (widget.vehicle.brand != null)
              _buildInfoRow('Hãng xe', widget.vehicle.brand!),
            if (widget.vehicle.color != null)
              _buildInfoRow('Màu xe', widget.vehicle.color!),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Thông tin tài xế', Icons.person, [
            _buildInfoRow('Họ tên', widget.vehicle.driverName),
            _buildInfoRow('Số điện thoại', widget.vehicle.driverPhone),
            if (widget.vehicle.driverLicense != null)
              _buildInfoRow('Số GPLX', widget.vehicle.driverLicense!),
            if (widget.vehicle.driverIdCard != null)
              _buildInfoRow('CMND/CCCD', widget.vehicle.driverIdCard!),
          ]),
          if (widget.vehicle.companyName != null) ...[
            const SizedBox(height: 16),
            _buildInfoSection('Công ty', Icons.business, [
              _buildInfoRow('Tên công ty', widget.vehicle.companyName!),
            ]),
          ],
          const SizedBox(height: 16),
          _buildInfoSection('Thời gian', Icons.access_time, [
            _buildInfoRow(
              'Tạo lúc',
              DateFormat('dd/MM/yyyy HH:mm').format(widget.vehicle.createdAt),
            ),
            if (widget.vehicle.updatedAt != null)
              _buildInfoRow(
                'Cập nhật',
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(widget.vehicle.updatedAt!),
              ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa thông tin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.vehicle.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đang hoạt động';
        break;
      case 'inactive':
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle;
        statusText = 'Không hoạt động';
        break;
      case 'blacklisted':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'Bị chặn';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Không xác định';
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.plateNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.vehicle.isApproved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Đã duyệt',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại xe',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildVehicleTypeChip('car', 'Ô tô', Icons.directions_car),
                _buildVehicleTypeChip('truck', 'Xe tải', Icons.local_shipping),
                _buildVehicleTypeChip(
                  'container',
                  'Container',
                  Icons.rv_hookup,
                ),
                _buildVehicleTypeChip(
                  'motorcycle',
                  'Xe máy',
                  Icons.two_wheeler,
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _plateNumberController,
              label: 'Biển số xe',
              hint: 'VD: 29A-12345',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              textInputAction: TextInputAction.next,
              validator: Validators.plateNumber,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _brandController,
              label: 'Hãng xe (tùy chọn)',
              hint: 'VD: Toyota, Ford...',
              prefixIcon: const Icon(Icons.branding_watermark_outlined),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _colorController,
              label: 'Màu xe (tùy chọn)',
              hint: 'VD: Trắng, Đen...',
              prefixIcon: const Icon(Icons.palette_outlined),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Thông tin tài xế',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _driverNameController,
              label: 'Tên tài xế',
              hint: 'Nhập tên tài xế',
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, 'Tên tài xế'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _driverPhoneController,
              label: 'SĐT tài xế',
              hint: 'Nhập số điện thoại',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _driverLicenseController,
              label: 'Số GPLX (tùy chọn)',
              hint: 'Nhập số giấy phép lái xe',
              prefixIcon: const Icon(Icons.badge_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            Consumer<VehicleProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: 'Lưu thay đổi',
                  onPressed: _handleSave,
                  isLoading: provider.isLoading,
                  width: double.infinity,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeChip(String value, String label, IconData icon) {
    final isSelected = _vehicleType == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _vehicleType = value;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: AppColors.textOnPrimary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
    );
  }
}
