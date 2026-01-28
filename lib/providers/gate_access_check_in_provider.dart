import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gate_access_registration_model.dart';
import '../models/gate_model.dart';
import '../models/visitor_access_log_model.dart';
import '../services/firestore_service.dart';
import '../services/gate_access_qr_service.dart';

/// Provider for guard app to handle gate access check-in/check-out via QR scan
class GateAccessCheckInProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State
  List<GateModel> _gates = [];
  GateModel? _selectedGate;

  // Scan result
  GateAccessQRResult? _qrResult;
  GateAccessRegistrationModel? _scannedRegistration;
  GateAccessValidationResult? _validationResult;

  // Loading and messages
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  // Stats
  int _todayCheckIns = 0;
  int _todayCheckOuts = 0;
  int _currentVisitorsInside = 0;

  // Subscriptions
  StreamSubscription? _gatesSubscription;
  StreamSubscription? _statsSubscription;

  // Getters
  List<GateModel> get gates => _gates;
  GateModel? get selectedGate => _selectedGate;
  GateAccessQRResult? get qrResult => _qrResult;
  GateAccessRegistrationModel? get scannedRegistration => _scannedRegistration;
  GateAccessValidationResult? get validationResult => _validationResult;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get todayCheckIns => _todayCheckIns;
  int get todayCheckOuts => _todayCheckOuts;
  int get currentVisitorsInside => _currentVisitorsInside;

  // Can perform actions (cho phép check-in/out ngay cả khi không có cổng)
  bool get canCheckIn =>
      _scannedRegistration != null &&
      _validationResult?.canCheckIn == true &&
      (_selectedGate == null || _selectedGate!.canCheckIn);

  bool get canCheckOut =>
      _scannedRegistration != null &&
      _validationResult?.canCheckOut == true &&
      (_selectedGate == null || _selectedGate!.canCheckOut);

  bool get hasValidScan =>
      _scannedRegistration != null && _validationResult?.isValid == true;

  /// Initialize provider
  void initialize() {
    _loadGates();
    _loadStats();
  }

  /// Load available gates
  void _loadGates() {
    _gatesSubscription?.cancel();
    _gatesSubscription = _firestoreService.getActiveGates().listen(
      (gates) {
        _gates = gates;
        if (_selectedGate == null && gates.isNotEmpty) {
          _selectedGate = gates.first;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không thể tải danh sách cổng';
        notifyListeners();
      },
    );
  }

  /// Load today's stats
  void _loadStats() {
    _statsSubscription?.cancel();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    _statsSubscription = FirebaseFirestore.instance
        .collection('visitorAccessLogs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .listen(
      (snapshot) {
        _todayCheckIns = 0;
        _todayCheckOuts = 0;

        final visitorStatus = <String, String>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final type = data['type'] as String?;
          final regId = data['registrationId'] as String?;

          if (type == 'check_in') {
            _todayCheckIns++;
          } else if (type == 'check_out') {
            _todayCheckOuts++;
          }

          if (regId != null && type != null) {
            visitorStatus[regId] = type;
          }
        }

        _currentVisitorsInside = visitorStatus.values
            .where((type) => type == 'check_in')
            .length;

        notifyListeners();
      },
      onError: (e) {
        // Silently fail
      },
    );
  }

  /// Select a gate
  void selectGate(GateModel gate) {
    _selectedGate = gate;
    notifyListeners();
  }

  /// Process QR scan
  Future<bool> processQRScan(String qrData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _scannedRegistration = null;
      _validationResult = null;
      notifyListeners();

      // 1. Parse QR code
      _qrResult = GateAccessQRService.parseQRCode(qrData);

      if (!_qrResult!.isValid) {
        _isLoading = false;
        _errorMessage = _qrResult!.errorMessage;
        notifyListeners();
        return false;
      }

      // 2. Get registration from Firestore
      final registration = await _firestoreService
          .getGateAccessRegistrationById(_qrResult!.registrationId!);

      if (registration == null) {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy thông tin đăng ký';
        notifyListeners();
        return false;
      }

      _scannedRegistration = registration;

      // 3. Validate registration
      // Determine if this is check-in or check-out based on current state
      final isCheckIn = !registration.isCurrentlyInside;
      _validationResult = GateAccessQRService.validateRegistration(
        registration,
        isCheckIn: isCheckIn,
      );

      if (!_validationResult!.isValid) {
        _isLoading = false;
        _errorMessage = _validationResult!.errorMessage;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi xử lý mã QR: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Perform check-in
  Future<bool> performCheckIn({
    required String guardId,
    required String guardName,
    String? note,
    bool holdIdCard = false,
    String? accessCardNumber,
  }) async {
    if (_scannedRegistration == null) {
      _errorMessage = 'Không có thông tin đăng ký';
      notifyListeners();
      return false;
    }

    if (!canCheckIn) {
      _errorMessage = 'Không thể check-in lúc này';
      notifyListeners();
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final reg = _scannedRegistration!;
      final now = DateTime.now();

      // Create visitor access log
      final log = VisitorAccessLogModel(
        id: '',
        registrationId: reg.id,
        visitorName: reg.fullName,
        visitorPhone: reg.phone,
        visitorIdCard: reg.idCard,
        visitorType: reg.visitorType,
        type: 'check_in',
        timestamp: now,
        gateId: _selectedGate?.id ?? 'default',
        gateName: _selectedGate?.gateName ?? 'Cổng chính',
        guardId: guardId,
        guardName: guardName,
        purpose: reg.purpose,
        addressOrCompany: reg.addressOrCompany ?? reg.companyName,
        vehiclePlate: reg.vehiclePlate,
        vehicleType: reg.vehicleType,
        idCardHeldByGuard: holdIdCard,
        accessCardNumber: accessCardNumber,
        note: note,
        createdAt: now,
      );

      await _firestoreService.createVisitorAccessLog(log);

      // Update registration with check-in info
      final updateData = <String, dynamic>{
        'actualCheckInTime': Timestamp.fromDate(now),
        'checkInGateId': _selectedGate?.id ?? 'default',
        'checkInGuardId': guardId,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (holdIdCard) {
        updateData['idCardHeldByGuard'] = true;
      }

      if (accessCardNumber != null && accessCardNumber.isNotEmpty) {
        updateData['accessCardNumber'] = accessCardNumber;
        updateData['accessCardIssued'] = true;
      }

      await _firestoreService.updateGateAccessRegistration(reg.id, updateData);

      _isProcessing = false;
      _successMessage = 'Check-in thành công: ${reg.fullName}';

      // Update validation result
      _validationResult = GateAccessValidationResult.valid(
        canCheckIn: false,
        canCheckOut: true,
      );

      // Refresh registration data
      _scannedRegistration = await _firestoreService.getGateAccessRegistrationById(reg.id);

      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Lỗi check-in: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Perform check-out
  Future<bool> performCheckOut({
    required String guardId,
    required String guardName,
    String? note,
    bool returnIdCard = false,
    bool returnAccessCard = false,
  }) async {
    if (_scannedRegistration == null) {
      _errorMessage = 'Không có thông tin đăng ký';
      notifyListeners();
      return false;
    }

    if (!canCheckOut) {
      _errorMessage = 'Không thể check-out lúc này';
      notifyListeners();
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final reg = _scannedRegistration!;
      final now = DateTime.now();

      // Create visitor access log
      final log = VisitorAccessLogModel(
        id: '',
        registrationId: reg.id,
        visitorName: reg.fullName,
        visitorPhone: reg.phone,
        visitorIdCard: reg.idCard,
        visitorType: reg.visitorType,
        type: 'check_out',
        timestamp: now,
        gateId: _selectedGate?.id ?? 'default',
        gateName: _selectedGate?.gateName ?? 'Cổng chính',
        guardId: guardId,
        guardName: guardName,
        purpose: reg.purpose,
        addressOrCompany: reg.addressOrCompany ?? reg.companyName,
        vehiclePlate: reg.vehiclePlate,
        vehicleType: reg.vehicleType,
        idCardHeldByGuard: returnIdCard ? false : reg.idCardHeldByGuard,
        accessCardNumber: reg.accessCardNumber,
        note: note,
        createdAt: now,
      );

      await _firestoreService.createVisitorAccessLog(log);

      // Update registration with check-out info
      final updateData = <String, dynamic>{
        'actualCheckOutTime': Timestamp.fromDate(now),
        'checkOutGateId': _selectedGate?.id ?? 'default',
        'checkOutGuardId': guardId,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (returnIdCard) {
        updateData['idCardHeldByGuard'] = false;
      }

      if (returnAccessCard) {
        updateData['accessCardIssued'] = false;
        updateData['accessCardNumber'] = null;
      }

      // For single-day registration, mark as used
      if (!reg.isMultipleDays) {
        updateData['status'] = 'used';
      }

      await _firestoreService.updateGateAccessRegistration(reg.id, updateData);

      _isProcessing = false;
      _successMessage = 'Check-out thành công: ${reg.fullName}';

      // Update validation result
      _validationResult = GateAccessValidationResult.valid(
        canCheckIn: reg.isMultipleDays, // Can check-in again if multiple days
        canCheckOut: false,
      );

      // Refresh registration data
      _scannedRegistration = await _firestoreService.getGateAccessRegistrationById(reg.id);

      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Lỗi check-out: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear scanned data
  void clearScanData() {
    _qrResult = null;
    _scannedRegistration = null;
    _validationResult = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Get status text
  String getStatusText() {
    if (_scannedRegistration == null) return 'Chưa quét';
    if (_scannedRegistration!.isCurrentlyInside) {
      return 'Đang ở trong nhà máy';
    }
    return 'Đang ở ngoài nhà máy';
  }

  /// Get recommended action
  String getRecommendedAction() {
    if (_validationResult == null) return '';
    if (_validationResult!.canCheckOut) return 'Check-out';
    if (_validationResult!.canCheckIn) return 'Check-in';
    return '';
  }

  /// Clear all data
  void clear() {
    _gatesSubscription?.cancel();
    _statsSubscription?.cancel();
    _gates = [];
    _selectedGate = null;
    _qrResult = null;
    _scannedRegistration = null;
    _validationResult = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gatesSubscription?.cancel();
    _statsSubscription?.cancel();
    super.dispose();
  }
}
