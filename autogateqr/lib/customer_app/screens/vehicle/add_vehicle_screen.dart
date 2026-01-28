import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_colors.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();

  String _vehicleType = 'car';

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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final provider = context.read<VehicleProvider>();

    final id = await provider.addVehicle(
      plateNumber: _plateNumberController.text.trim().toUpperCase(),
      vehicleType: _vehicleType,
      driverName: _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim(),
      ownerId: user.uid,
      brand: _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      color: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      driverLicense: _driverLicenseController.text.trim().isNotEmpty
          ? _driverLicenseController.text.trim()
          : null,
      companyId: user.companyId,
      companyName: user.companyName,
    );

    if (id != null && mounted) {
      Helpers.showSuccessSnackBar(context, 'Thêm xe thành công');
      Navigator.pop(context);
    } else if (provider.errorMessage != null && mounted) {
      Helpers.showErrorSnackBar(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm xe mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle type
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
                  _buildVehicleTypeChip('container', 'Container', Icons.rv_hookup),
                  _buildVehicleTypeChip('motorcycle', 'Xe máy', Icons.two_wheeler),
                ],
              ),
              const SizedBox(height: 24),

              // Plate number
              CustomTextField(
                controller: _plateNumberController,
                label: 'Biển số xe',
                hint: 'VD: 29A-12345',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                textInputAction: TextInputAction.next,
                validator: Validators.plateNumber,
              ),
              const SizedBox(height: 16),

              // Brand (optional)
              CustomTextField(
                controller: _brandController,
                label: 'Hãng xe (tùy chọn)',
                hint: 'VD: Toyota, Ford...',
                prefixIcon: const Icon(Icons.branding_watermark_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Color (optional)
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Driver name
              CustomTextField(
                controller: _driverNameController,
                label: 'Tên tài xế',
                hint: 'Nhập tên tài xế',
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(value, 'Tên tài xế'),
              ),
              const SizedBox(height: 16),

              // Driver phone
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

              // Driver license (optional)
              CustomTextField(
                controller: _driverLicenseController,
                label: 'Số GPLX (tùy chọn)',
                hint: 'Nhập số giấy phép lái xe',
                prefixIcon: const Icon(Icons.badge_outlined),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Submit button
              Consumer<VehicleProvider>(
                builder: (context, provider, _) {
                  return CustomButton(
                    text: 'Thêm xe',
                    onPressed: _handleSubmit,
                    isLoading: provider.isLoading,
                    width: double.infinity,
                  );
                },
              ),
            ],
          ),
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