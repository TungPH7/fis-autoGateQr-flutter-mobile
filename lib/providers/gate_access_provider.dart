import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/gate_access_registration_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/gate_access_qr_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing gate access registrations
/// Handles: creating registrations, viewing status, displaying approved QR
class GateAccessProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State
  String? _currentUserId;
  List<GateAccessRegistrationModel> _allRegistrations = [];
  List<GateAccessRegistrationModel> _pendingRegistrations = [];
  List<GateAccessRegistrationModel> _approvedRegistrations = [];
  List<GateAccessRegistrationModel> _todayApprovedRegistrations = [];
  GateAccessRegistrationModel? _selectedRegistration;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Subscriptions
  StreamSubscription? _registrationsSubscription;
  StreamSubscription? _todayApprovedSubscription;

  // Getters
  List<GateAccessRegistrationModel> get allRegistrations => _allRegistrations;
  List<GateAccessRegistrationModel> get pendingRegistrations => _pendingRegistrations;
  List<GateAccessRegistrationModel> get approvedRegistrations => _approvedRegistrations;
  List<GateAccessRegistrationModel> get todayApprovedRegistrations => _todayApprovedRegistrations;
  GateAccessRegistrationModel? get selectedRegistration => _selectedRegistration;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Check if user has valid QR for today
  bool get hasValidQRForToday {
    return _todayApprovedRegistrations.any((reg) => reg.hasValidQR);
  }

  // Get first valid registration for today (for QR display)
  GateAccessRegistrationModel? get activeRegistrationForToday {
    try {
      return _todayApprovedRegistrations.firstWhere((reg) => reg.hasValidQR);
    } catch (e) {
      return null;
    }
  }

  /// Initialize provider for a user
  void initializeForUser(String userId) {
    _currentUserId = userId;
    _loadRegistrations();
    _loadTodayApprovedRegistrations();
  }

  /// Load all registrations for current user
  void _loadRegistrations() {
    _registrationsSubscription?.cancel();
    if (_currentUserId == null) return;

    _registrationsSubscription = _firestoreService
        .getGateAccessRegistrationsByUser(_currentUserId!)
        .listen(
      (registrations) {
        _allRegistrations = registrations;
        _pendingRegistrations =
            registrations.where((r) => r.isPending).toList();
        _approvedRegistrations =
            registrations.where((r) => r.isApproved).toList();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không thể tải danh sách đăng ký';
        notifyListeners();
      },
    );
  }

  /// Load today's approved registrations (for QR display)
  void _loadTodayApprovedRegistrations() {
    _todayApprovedSubscription?.cancel();
    if (_currentUserId == null) return;

    _todayApprovedSubscription = _firestoreService
        .getApprovedRegistrationsForToday(_currentUserId!)
        .listen(
      (registrations) {
        _todayApprovedRegistrations = registrations;
        notifyListeners();
      },
      onError: (e) {
        // Silently fail - will show no QR
      },
    );
  }

  /// Create a new gate access registration (by user via app)
  Future<bool> createRegistration({
    required UserModel user,
    required String visitorType,
    required String fullName,
    required String phone,
    String? email,
    String? addressOrCompany,
    String? idCard,
    required String purpose,
    String? visitDepartment,
    String? hostName,
    String? hostPhone,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    String accessType = 'both',
    String? vehiclePlate,
    String? vehicleType,
    String? cccdPhotoUrl,
    String? note,
    bool isMultipleDays = false,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      final registration = GateAccessRegistrationModel(
        id: '',
        visitorType: visitorType,
        fullName: fullName,
        phone: phone,
        email: email ?? user.email,
        addressOrCompany: addressOrCompany ?? user.company,
        idCard: idCard,
        photoUrl: cccdPhotoUrl ?? user.photoUrl,
        userId: user.id,
        expectedDate: expectedDate,
        expectedTimeFrom: expectedTimeFrom,
        expectedTimeTo: expectedTimeTo,
        accessType: accessType,
        purpose: purpose,
        visitDepartment: visitDepartment,
        hostName: hostName,
        hostPhone: hostPhone,
        status: AppConstants.statusPending,
        createdAt: DateTime.now(),
        vehiclePlate: vehiclePlate,
        vehicleType: vehicleType,
        note: note,
        isMultipleDays: isMultipleDays,
        endDate: isMultipleDays ? endDate : null,
      );

      await _firestoreService.createGateAccessRegistration(registration);

      _isLoading = false;
      _successMessage = 'Đã gửi yêu cầu đăng ký thành công. Vui lòng chờ duyệt.';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi tạo đăng ký: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Create registration by guard (for walk-in visitors)
  Future<bool> createRegistrationByGuard({
    required String guardId,
    required String visitorType,
    required String fullName,
    required String phone,
    String? email,
    String? addressOrCompany,
    String? idCard,
    required String purpose,
    String? visitDepartment,
    String? hostName,
    String? hostPhone,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    String accessType = 'both',
    String? vehiclePlate,
    String? vehicleType,
    String? cccdPhotoUrl,
    String? note,
    bool idCardHeldByGuard = false,
    String? accessCardNumber,
    bool accessCardIssued = false,
    bool autoApprove = true,
    bool isMultipleDays = false,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      final registration = GateAccessRegistrationModel(
        id: '',
        visitorType: visitorType,
        fullName: fullName,
        phone: phone,
        email: email,
        addressOrCompany: addressOrCompany,
        idCard: idCard,
        photoUrl: cccdPhotoUrl,
        userId: null, // Not a registered user
        expectedDate: expectedDate,
        expectedTimeFrom: expectedTimeFrom,
        expectedTimeTo: expectedTimeTo,
        accessType: accessType,
        purpose: purpose,
        visitDepartment: visitDepartment,
        hostName: hostName,
        hostPhone: hostPhone,
        status: autoApprove ? AppConstants.statusApproved : AppConstants.statusPending,
        approvedBy: autoApprove ? guardId : null,
        approvedAt: autoApprove ? DateTime.now() : null,
        createdAt: DateTime.now(),
        createdBy: guardId,
        vehiclePlate: vehiclePlate,
        vehicleType: vehicleType,
        note: note,
        idCardHeldByGuard: idCardHeldByGuard,
        accessCardNumber: accessCardNumber,
        accessCardIssued: accessCardIssued,
        isMultipleDays: isMultipleDays,
        endDate: isMultipleDays ? endDate : null,
      );

      final regId = await _firestoreService.createGateAccessRegistration(registration);

      // If auto-approved, generate QR code
      if (autoApprove) {
        final qrCode = _generateQRCode(
          registrationId: regId,
          expectedDate: expectedDate,
          expectedTimeFrom: expectedTimeFrom,
          expectedTimeTo: expectedTimeTo,
          isMultipleDays: isMultipleDays,
          endDate: endDate,
        );
        // QR expires at end of endDate if multiple days, otherwise end of expectedDate
        final expiryDate = isMultipleDays && endDate != null ? endDate : expectedDate;
        final qrExpiresAt = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
          23, 59, 59,
        );

        await _firestoreService.updateGateAccessRegistration(regId, {
          'qrCode': qrCode,
          'qrExpiresAt': qrExpiresAt,
        });
      }

      _isLoading = false;
      _successMessage = autoApprove
          ? 'Đã đăng ký và tạo QR thành công'
          : 'Đã gửi yêu cầu đăng ký';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi tạo đăng ký: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  String _generateQRCode({
    required String registrationId,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    bool isMultipleDays = false,
    DateTime? endDate,
  }) {
    return GateAccessQRService.generateQRCode(
      registrationId: registrationId,
      expectedDate: expectedDate,
      expectedTimeFrom: expectedTimeFrom,
      expectedTimeTo: expectedTimeTo,
      isMultipleDays: isMultipleDays,
      endDate: endDate,
    );
  }

  /// Cancel a pending registration
  Future<bool> cancelRegistration(String registrationId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.cancelGateAccessRegistration(registrationId);

      _isLoading = false;
      _successMessage = 'Đã hủy đăng ký';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hủy đăng ký: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get registration by ID
  Future<GateAccessRegistrationModel?> getRegistrationById(
      String registrationId) async {
    try {
      return await _firestoreService
          .getGateAccessRegistrationById(registrationId);
    } catch (e) {
      return null;
    }
  }

  /// Select a registration for viewing details
  void selectRegistration(GateAccessRegistrationModel registration) {
    _selectedRegistration = registration;
    notifyListeners();
  }

  /// Clear selected registration
  void clearSelectedRegistration() {
    _selectedRegistration = null;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Refresh data
  void refresh() {
    _loadRegistrations();
    _loadTodayApprovedRegistrations();
  }

  /// Clear all data
  void clear() {
    _registrationsSubscription?.cancel();
    _todayApprovedSubscription?.cancel();
    _currentUserId = null;
    _allRegistrations = [];
    _pendingRegistrations = [];
    _approvedRegistrations = [];
    _todayApprovedRegistrations = [];
    _selectedRegistration = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _registrationsSubscription?.cancel();
    _todayApprovedSubscription?.cancel();
    super.dispose();
  }
}
