import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gate_access_provider.dart';
import '../../../shared/widgets/cccd_photo_picker.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class GuardManualRegistrationScreen extends StatefulWidget {
  const GuardManualRegistrationScreen({super.key});

  @override
  State<GuardManualRegistrationScreen> createState() =>
      _GuardManualRegistrationScreenState();
}

class _GuardManualRegistrationScreenState
    extends State<GuardManualRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Personal info controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressOrCompanyController = TextEditingController();
  final _idCardController = TextEditingController();
  final _accessCardController = TextEditingController();

  // Vehicle controller
  final _vehiclePlateController = TextEditingController();

  // Purpose controllers
  final _purposeController = TextEditingController();
  final _visitDepartmentController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _hostPhoneController = TextEditingController();
  final _noteController = TextEditingController();

  // State
  String _visitorType = 'visitor';
  String _accessType = 'both';
  String? _vehicleType;
  String? _cccdPhotoUrl;
  bool _idCardHeldByGuard = false;
  bool _issueAccessCard = false;

  // Time state
  bool _isMultipleDays = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay? _expectedTimeFrom;
  TimeOfDay? _expectedTimeTo;

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressOrCompanyController.dispose();
    _idCardController.dispose();
    _accessCardController.dispose();
    _vehiclePlateController.dispose();
    _purposeController.dispose();
    _visitDepartmentController.dispose();
    _hostNameController.dispose();
    _hostPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final guard = context.read<AuthProvider>().user;
    if (guard == null) {
      Helpers.showErrorSnackBar(context, 'Không tìm thấy thông tin bảo vệ');
      return;
    }

    final provider = context.read<GateAccessProvider>();

    DateTime? timeFrom;
    DateTime? timeTo;

    if (_expectedTimeFrom != null) {
      timeFrom = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _expectedTimeFrom!.hour,
        _expectedTimeFrom!.minute,
      );
    }

    if (_expectedTimeTo != null) {
      timeTo = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _expectedTimeTo!.hour,
        _expectedTimeTo!.minute,
      );
    }

    final success = await provider.createRegistrationByGuard(
      guardId: guard.id,
      visitorType: _visitorType,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      addressOrCompany: _addressOrCompanyController.text.trim().isNotEmpty
          ? _addressOrCompanyController.text.trim()
          : null,
      idCard: _idCardController.text.trim().isNotEmpty
          ? _idCardController.text.trim()
          : null,
      purpose: _purposeController.text.trim(),
      visitDepartment: _visitDepartmentController.text.trim().isNotEmpty
          ? _visitDepartmentController.text.trim()
          : null,
      hostName: _hostNameController.text.trim().isNotEmpty
          ? _hostNameController.text.trim()
          : null,
      hostPhone: _hostPhoneController.text.trim().isNotEmpty
          ? _hostPhoneController.text.trim()
          : null,
      expectedDate: _startDate,
      expectedTimeFrom: timeFrom,
      expectedTimeTo: timeTo,
      accessType: _accessType,
      vehiclePlate: _vehiclePlateController.text.trim().isNotEmpty
          ? _vehiclePlateController.text.trim().toUpperCase()
          : null,
      vehicleType: _vehicleType,
      cccdPhotoUrl: _cccdPhotoUrl,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      idCardHeldByGuard: _idCardHeldByGuard,
      accessCardNumber:
          _issueAccessCard && _accessCardController.text.trim().isNotEmpty
          ? _accessCardController.text.trim()
          : null,
      accessCardIssued: _issueAccessCard,
      autoApprove: true,
      isMultipleDays: _isMultipleDays,
      endDate: _isMultipleDays ? _endDate : null,
    );

    if (success && mounted) {
      Helpers.showSuccessSnackBar(
        context,
        'Đăng ký thành công! Khách có thể vào cổng.',
      );
      Navigator.pop(context);
    } else if (provider.errorMessage != null && mounted) {
      Helpers.showErrorSnackBar(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký trực tiếp'),
        backgroundColor: AppColors.guardPrimary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice for guard
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.guardPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.guardPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.guardPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nhập thông tin khách/nhân viên/nhà thầu đến trực tiếp tại cổng.',
                        style: TextStyle(
                          color: AppColors.guardPrimary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== THÔNG TIN CÁ NHÂN =====
              _buildSectionTitle('Thông tin cá nhân'),
              const SizedBox(height: 12),

              // Visitor Type
              const Text(
                'Loại đối tượng',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'visitor',
                    label: Text('Khách/Nhà thầu'),
                    icon: Icon(Icons.person, size: 18),
                  ),
                  ButtonSegment(
                    value: 'employee',
                    label: Text('Nhân viên'),
                    icon: Icon(Icons.badge, size: 18),
                  ),
                ],
                selected: {_visitorType},
                onSelectionChanged: (selected) {
                  setState(() => _visitorType = selected.first);
                },
              ),
              const SizedBox(height: 16),

              // Full Name
              CustomTextField(
                controller: _fullNameController,
                label: 'Họ và tên *',
                hint: 'Nhập họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(value, 'Họ và tên'),
              ),
              const SizedBox(height: 12),

              // Email
              CustomTextField(
                controller: _emailController,
                label: 'Email *',
                hint: 'Nhập email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 24),

              // Phone
              CustomTextField(
                controller: _phoneController,
                label: 'Số điện thoại *',
                hint: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),

              // Địa chỉ/Công ty
              CustomTextField(
                controller: _addressOrCompanyController,
                label: 'Địa chỉ / Tên công ty',
                hint: 'Nhập địa chỉ hoặc tên công ty',
                prefixIcon: const Icon(Icons.business_outlined),
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // ID Card (CCCD)
              CustomTextField(
                controller: _idCardController,
                label: 'Số CCCD/CMND',
                hint: 'Nhập số giấy tờ tùy thân (tùy chọn)',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.credit_card_outlined),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              const SizedBox(height: 12),

              // CCCD Photo
              CCCDPhotoPicker(
                initialPhotoUrl: _cccdPhotoUrl,
                onPhotoChanged: (url) => setState(() => _cccdPhotoUrl = url),
                primaryColor: AppColors.guardPrimary,
              ),
              const SizedBox(height: 12),

              // Checkbox - Bảo vệ giữ CCCD
              CheckboxListTile(
                value: _idCardHeldByGuard,
                onChanged: (value) {
                  setState(() => _idCardHeldByGuard = value ?? false);
                },
                title: const Text('Bảo vệ giữ CCCD'),
                subtitle: const Text(
                  'Đánh dấu nếu bảo vệ giữ CCCD của khách',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.orange,
              ),
              const SizedBox(height: 12),

              // ===== THẺ RA VÀO =====
              _buildSectionTitle('Thẻ ra vào'),
              const SizedBox(height: 12),

              CheckboxListTile(
                value: _issueAccessCard,
                onChanged: (value) {
                  setState(() {
                    _issueAccessCard = value ?? false;
                    if (!_issueAccessCard) {
                      _accessCardController.clear();
                    }
                  });
                },
                title: const Text('Cấp thẻ ra vào'),
                subtitle: const Text(
                  'Đánh dấu nếu bảo vệ cấp thẻ ra vào cho khách',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.blue,
              ),

              if (_issueAccessCard) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _accessCardController,
                  label: 'Mã thẻ ra vào *',
                  hint: 'Nhập mã thẻ ra vào',
                  prefixIcon: const Icon(Icons.credit_card),
                  textInputAction: TextInputAction.next,
                  validator: _issueAccessCard
                      ? (value) => Validators.required(value, 'Mã thẻ ra vào')
                      : null,
                ),
              ],
              const SizedBox(height: 24),

              // ===== THỜI GIAN =====
              _buildSectionTitle('Thời gian'),
              const SizedBox(height: 12),

              // Access Type
              const Text(
                'Loại đăng ký',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'both',
                    label: Text('Ra/Vào'),
                    icon: Icon(Icons.swap_horiz, size: 18),
                  ),
                ],
                selected: {_accessType},
                onSelectionChanged: (selected) {
                  setState(() => _accessType = selected.first);
                },
              ),

              // Multiple days checkbox
              CheckboxListTile(
                value: _isMultipleDays,
                onChanged: (value) {
                  setState(() {
                    _isMultipleDays = value ?? false;
                    if (!_isMultipleDays) {
                      _endDate = _startDate;
                    }
                  });
                },
                title: const Text('Đăng ký nhiều ngày'),
                subtitle: const Text(
                  'Mã QR có thể sử dụng trong nhiều ngày',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.guardPrimary,
              ),

              // Date selection
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: _isMultipleDays ? 'Từ ngày' : 'Ngày',
                      date: _startDate,
                      onTap: () => _selectDate(isStart: true),
                    ),
                  ),
                  if (_isMultipleDays) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateSelector(
                        label: 'Đến ngày',
                        date: _endDate,
                        onTap: () => _selectDate(isStart: false),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ===== MỤC ĐÍCH =====
              _buildSectionTitle('Mục đích'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _purposeController,
                label: 'Mục đích *',
                hint: 'VD: Làm việc, Giao hàng, Bảo trì, Họp...',
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 2,
                validator: (value) => Validators.required(value, 'Mục đích'),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _visitDepartmentController,
                label: 'Phòng ban đến làm việc',
                hint: 'VD: Phòng kỹ thuật, Phòng nhân sự...',
                prefixIcon: const Icon(Icons.meeting_room_outlined),
              ),
              const SizedBox(height: 24),

              // ===== PHƯƠNG TIỆN =====
              _buildSectionTitle('Phương tiện'),
              const SizedBox(height: 12),

              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(
                    value: null,
                    label: Text('Không'),
                    icon: Icon(Icons.not_interested, size: 18),
                  ),
                  ButtonSegment(
                    value: 'car',
                    label: Text('Ô tô'),
                    icon: Icon(Icons.directions_car, size: 18),
                  ),
                  ButtonSegment(
                    value: 'motorcycle',
                    label: Text('Xe máy'),
                    icon: Icon(Icons.two_wheeler, size: 18),
                  ),
                ],
                selected: {_vehicleType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _vehicleType = selected.first;
                    if (_vehicleType == null) {
                      _vehiclePlateController.clear();
                    }
                  });
                },
              ),

              if (_vehicleType != null) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _vehiclePlateController,
                  label: 'Biển số xe',
                  hint: 'VD: 51A-123.45',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  textInputAction: TextInputAction.done,
                ),
              ],
              const SizedBox(height: 24),

              // ===== GHI CHÚ =====
              _buildSectionTitle('Ghi chú'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _noteController,
                label: 'Ghi chú thêm',
                hint: 'Nhập ghi chú nếu cần',
                maxLines: 3,
                prefixIcon: const Icon(Icons.note_outlined),
              ),
              const SizedBox(height: 24),

              // Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đăng ký sẽ được duyệt tự động. Khách có thể vào cổng ngay sau khi xác nhận.',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer<GateAccessProvider>(
                    builder: (context, provider, _) {
                      return CustomButton(
                        text: 'Xác nhận đăng ký',
                        onPressed: _handleSubmit,
                        isLoading: provider.isLoading,
                        icon: Icons.check_circle,
                        backgroundColor: AppColors.guardPrimary,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.guardPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: AppColors.guardPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    Helpers.formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
