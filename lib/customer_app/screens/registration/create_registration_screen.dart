import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../models/registration_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/vehicle_card.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class CreateRegistrationScreen extends StatefulWidget {
  const CreateRegistrationScreen({super.key});

  @override
  State<CreateRegistrationScreen> createState() => _CreateRegistrationScreenState();
}

class _CreateRegistrationScreenState extends State<CreateRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _registrationType = AppConstants.regTypeBoth;
  DateTime _expectedDate = DateTime.now();
  TimeOfDay? _expectedTimeFrom;
  TimeOfDay? _expectedTimeTo;
  VehicleModel? _selectedVehicle;

  int _currentStep = 0;

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _purposeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        Duration(days: AppConstants.maxAdvanceRegistrationDays),
      ),
    );
    if (date != null) {
      setState(() {
        _expectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isFrom) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isFrom
          ? (_expectedTimeFrom ?? TimeOfDay.now())
          : (_expectedTimeTo ?? TimeOfDay.now()),
    );
    if (time != null) {
      setState(() {
        if (isFrom) {
          _expectedTimeFrom = time;
        } else {
          _expectedTimeTo = time;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicle == null) {
      Helpers.showErrorSnackBar(context, 'Vui lòng chọn xe');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final provider = context.read<RegistrationProvider>();

    DateTime? timeFrom;
    DateTime? timeTo;

    if (_expectedTimeFrom != null) {
      timeFrom = DateTime(
        _expectedDate.year,
        _expectedDate.month,
        _expectedDate.day,
        _expectedTimeFrom!.hour,
        _expectedTimeFrom!.minute,
      );
    }

    if (_expectedTimeTo != null) {
      timeTo = DateTime(
        _expectedDate.year,
        _expectedDate.month,
        _expectedDate.day,
        _expectedTimeTo!.hour,
        _expectedTimeTo!.minute,
      );
    }

    final id = await provider.createRegistration(
      userId: user.uid,
      userFullName: user.fullName,
      registrationType: _registrationType,
      companyId: user.companyId,
      companyName: user.companyName,
      vehicleId: _selectedVehicle!.id,
      plateNumber: _selectedVehicle!.plateNumber,
      vehicleType: _selectedVehicle!.vehicleType,
      driverInfo: DriverInfo(
        name: _driverNameController.text.trim(),
        phone: _driverPhoneController.text.trim(),
      ),
      visitPurpose: _purposeController.text.trim(),
      visitLocation: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      expectedDate: _expectedDate,
      expectedTimeFrom: timeFrom,
      expectedTimeTo: timeTo,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (id != null && mounted) {
      Helpers.showSuccessSnackBar(context, 'Tạo đăng ký thành công');
      Navigator.pop(context);
    } else if (provider.errorMessage != null && mounted) {
      Helpers.showErrorSnackBar(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đăng ký mới'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep++;
              });
            } else {
              _handleSubmit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            }
          },
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 2)
                    Expanded(
                      child: CustomButton(
                        text: 'Tiếp tục',
                        onPressed: details.onStepContinue,
                      ),
                    )
                  else
                    Expanded(
                      child: Consumer<RegistrationProvider>(
                        builder: (context, provider, _) {
                          return CustomButton(
                            text: 'Gửi đăng ký',
                            onPressed: details.onStepContinue,
                            isLoading: provider.isLoading,
                          );
                        },
                      ),
                    ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Quay lại',
                        onPressed: details.onStepCancel,
                        isOutlined: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Step 1: Select vehicle
            Step(
              title: const Text('Chọn xe'),
              subtitle: _selectedVehicle != null
                  ? Text(_selectedVehicle!.plateNumber)
                  : null,
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildVehicleStep(),
            ),

            // Step 2: Driver & Purpose
            Step(
              title: const Text('Thông tin chuyến đi'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildInfoStep(),
            ),

            // Step 3: Date & Time
            Step(
              title: const Text('Ngày giờ'),
              subtitle: Text(Helpers.formatDate(_expectedDate)),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildDateTimeStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleStep() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, _) {
        if (provider.activeVehicles.isEmpty) {
          return Column(
            children: [
              const Text(
                'Bạn chưa có xe nào. Vui lòng thêm xe trước.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Thêm xe mới',
                onPressed: () {
                  Navigator.pushNamed(context, '/customer/vehicles/add');
                },
                icon: Icons.add,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: provider.activeVehicles.map((vehicle) {
            return VehicleSelectCard(
              vehicle: vehicle,
              isSelected: _selectedVehicle?.id == vehicle.id,
              onTap: () {
                setState(() {
                  _selectedVehicle = vehicle;
                  _driverNameController.text = vehicle.driverName;
                  _driverPhoneController.text = vehicle.driverPhone;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Registration type
        const Text(
          'Loại đăng ký',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: AppConstants.regTypeEntry,
              label: Text('Vào'),
              icon: Icon(Icons.login),
            ),
            ButtonSegment(
              value: AppConstants.regTypeExit,
              label: Text('Ra'),
              icon: Icon(Icons.logout),
            ),
            ButtonSegment(
              value: AppConstants.regTypeBoth,
              label: Text('Ra/Vào'),
              icon: Icon(Icons.swap_horiz),
            ),
          ],
          selected: {_registrationType},
          onSelectionChanged: (selected) {
            setState(() {
              _registrationType = selected.first;
            });
          },
        ),
        const SizedBox(height: 16),

        // Driver name
        CustomTextField(
          controller: _driverNameController,
          label: 'Tên tài xế',
          hint: 'Nhập tên tài xế',
          prefixIcon: const Icon(Icons.person_outline),
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
          validator: Validators.phone,
        ),
        const SizedBox(height: 16),

        // Purpose
        CustomTextField(
          controller: _purposeController,
          label: 'Mục đích',
          hint: 'Nhập mục đích ra/vào',
          prefixIcon: const Icon(Icons.description_outlined),
          maxLines: 2,
          validator: (value) => Validators.required(value, 'Mục đích'),
        ),
        const SizedBox(height: 16),

        // Location (optional)
        CustomTextField(
          controller: _locationController,
          label: 'Địa điểm (tùy chọn)',
          hint: 'Nhập địa điểm đến',
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: const Text('Ngày dự kiến'),
          subtitle: Text(Helpers.formatDate(_expectedDate)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectDate,
        ),
        const Divider(),

        // Time from
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: const Text('Giờ vào (tùy chọn)'),
          subtitle: Text(
            _expectedTimeFrom != null
                ? _expectedTimeFrom!.format(context)
                : 'Chưa chọn',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectTime(true),
        ),
        const Divider(),

        // Time to
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: const Text('Giờ ra (tùy chọn)'),
          subtitle: Text(
            _expectedTimeTo != null
                ? _expectedTimeTo!.format(context)
                : 'Chưa chọn',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectTime(false),
        ),
        const Divider(),
        const SizedBox(height: 16),

        // Notes
        CustomTextField(
          controller: _notesController,
          label: 'Ghi chú (tùy chọn)',
          hint: 'Nhập ghi chú thêm',
          maxLines: 3,
          prefixIcon: const Icon(Icons.note_outlined),
        ),
      ],
    );
  }
}
