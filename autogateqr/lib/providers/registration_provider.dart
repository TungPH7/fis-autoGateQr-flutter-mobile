import 'package:flutter/foundation.dart';
import '../models/registration_model.dart';
import '../services/firestore_service.dart';
import '../services/qr_service.dart';
import '../core/constants/app_constants.dart';

class RegistrationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<RegistrationModel> _registrations = [];
  RegistrationModel? _selectedRegistration;
  bool _isLoading = false;
  String? _errorMessage;

  List<RegistrationModel> get registrations => _registrations;
  RegistrationModel? get selectedRegistration => _selectedRegistration;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered lists
  List<RegistrationModel> get pendingRegistrations =>
      _registrations.where((r) => r.isPending).toList();

  List<RegistrationModel> get approvedRegistrations =>
      _registrations.where((r) => r.isApproved).toList();

  List<RegistrationModel> get completedRegistrations =>
      _registrations.where((r) => r.isCompleted).toList();

  // Load registrations for user
  void loadRegistrations(String userId) {
    _firestoreService.getRegistrationsByUser(userId).listen(
      (registrations) {
        _registrations = registrations;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Không thể tải danh sách đăng ký';
        notifyListeners();
      },
    );
  }

  // Get registration by ID
  Future<RegistrationModel?> getRegistrationById(String registrationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final registration = await _firestoreService.getRegistrationById(registrationId);
      _selectedRegistration = registration;
      _isLoading = false;
      notifyListeners();

      return registration;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải thông tin đăng ký';
      notifyListeners();
      return null;
    }
  }

  // Create new registration
  Future<String?> createRegistration({
    required String userId,
    required String userFullName,
    required String registrationType,
    String? companyId,
    String? companyName,
    String? vehicleId,
    String? plateNumber,
    String? vehicleType,
    required DriverInfo driverInfo,
    required String visitPurpose,
    String? visitLocation,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    CargoInfo? cargoInfo,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final registration = RegistrationModel(
        id: '',
        registrationType: registrationType,
        companyId: companyId,
        companyName: companyName,
        userId: userId,
        userFullName: userFullName,
        vehicleId: vehicleId,
        plateNumber: plateNumber,
        vehicleType: vehicleType,
        driverInfo: driverInfo,
        visitPurpose: visitPurpose,
        visitLocation: visitLocation,
        expectedDate: expectedDate,
        expectedTimeFrom: expectedTimeFrom,
        expectedTimeTo: expectedTimeTo,
        cargoInfo: cargoInfo,
        status: AppConstants.statusPending,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final id = await _firestoreService.createRegistration(registration);
      _isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tạo đăng ký: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Update registration
  Future<bool> updateRegistration(String registrationId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateRegistration(registrationId, data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể cập nhật đăng ký';
      notifyListeners();
      return false;
    }
  }

  // Select registration
  void selectRegistration(RegistrationModel? registration) {
    _selectedRegistration = registration;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get QR data for display
  String? getQRDataForDisplay(RegistrationModel registration) {
    if (registration.qrCode != null) {
      return registration.qrCode;
    }
    return QRService.generateRegistrationQRData(registration);
  }
}