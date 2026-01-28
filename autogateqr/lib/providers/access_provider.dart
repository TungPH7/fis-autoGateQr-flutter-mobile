import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/access_log_model.dart';
import '../models/visitor_access_log_model.dart';
import '../models/user_model.dart';
import '../models/gate_model.dart';
import '../services/firestore_service.dart';
import '../services/qr_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing access logs and check-in/check-out operations
class AccessProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State
  String? _currentUserId;
  String? _currentUserPhone;
  String? _currentUserType; // 'employee', 'contractor', 'visitor'
  List<VisitorAccessLogModel> _accessHistory = [];
  VisitorAccessLogModel? _lastAccessLog;
  bool _isInside = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // For guard scanner
  UserModel? _scannedUser;
  QRValidationResult? _lastScanResult;

  // Stream subscriptions
  StreamSubscription? _historySubscription;

  // Getters
  List<VisitorAccessLogModel> get accessHistory => _accessHistory;
  VisitorAccessLogModel? get lastAccessLog => _lastAccessLog;
  bool get isInside => _isInside;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserModel? get scannedUser => _scannedUser;
  QRValidationResult? get lastScanResult => _lastScanResult;
  String? get currentUserType => _currentUserType;

  /// Initialize for a user (employee/contractor/visitor side) with phone number and user type
  void initializeForUser(String userId, {String? phone, String? userType}) {
    _currentUserId = userId;
    _currentUserPhone = phone;
    _currentUserType = userType;
    if (phone != null && phone.isNotEmpty) {
      _loadAccessHistoryByPhone();
      _checkCurrentStatusByPhone();
    }
  }

  /// Set user phone (call this after getting user info)
  void setUserPhone(String phone, {String? userType}) {
    _currentUserPhone = phone;
    if (userType != null) {
      _currentUserType = userType;
    }
    _loadAccessHistoryByPhone();
    _checkCurrentStatusByPhone();
  }

  /// Load access history by phone (last 7 days) from visitorAccessLogs
  /// Filters by visitorType if userType is provided
  void _loadAccessHistoryByPhone() {
    _historySubscription?.cancel();
    if (_currentUserPhone == null || _currentUserPhone!.isEmpty) return;

    _historySubscription = _firestoreService
        .getVisitorAccessLogsByPhoneAndType(
          _currentUserPhone!,
          visitorType: _currentUserType,
          days: AppConstants.accessHistoryDays,
        )
        .listen(
      (logs) {
        _accessHistory = logs;
        if (logs.isNotEmpty) {
          _lastAccessLog = logs.first;
          _updateInsideStatus();
        } else {
          _lastAccessLog = null;
          _isInside = false;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không thể tải lịch sử ra/vào';
        notifyListeners();
      },
    );
  }

  /// Check current inside/outside status by phone
  Future<void> _checkCurrentStatusByPhone() async {
    if (_currentUserPhone == null || _currentUserPhone!.isEmpty) return;
    _isInside = await _firestoreService.isUserInsideByPhoneAndType(
      _currentUserPhone!,
      visitorType: _currentUserType,
    );
    notifyListeners();
  }

  /// Update inside status based on last log
  void _updateInsideStatus() {
    if (_lastAccessLog == null) {
      _isInside = false;
      return;
    }

    // Check if the last log was today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(
      _lastAccessLog!.timestamp.year,
      _lastAccessLog!.timestamp.month,
      _lastAccessLog!.timestamp.day,
    );

    _isInside = logDate == today && _lastAccessLog!.isCheckIn;
  }

  /// Process QR scan (guard side)
  Future<bool> processQRScan(String qrData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _scannedUser = null;
      notifyListeners();

      // Validate QR data
      final validationResult = QRService.parseQRData(qrData);
      _lastScanResult = validationResult;

      if (!validationResult.isValid) {
        _isLoading = false;
        _errorMessage = validationResult.errorMessage;
        notifyListeners();
        return false;
      }

      // Get user from Firestore
      final user = await _firestoreService.getUserById(validationResult.userId!);

      if (user == null) {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy thông tin người dùng';
        notifyListeners();
        return false;
      }

      // Validate user status
      if (!user.isActive) {
        _isLoading = false;
        _errorMessage = 'Tài khoản đã bị vô hiệu hóa: ${user.statusDisplay}';
        notifyListeners();
        return false;
      }

      // Validate user validity period (for contractors)
      if (!user.isValidPeriod) {
        _isLoading = false;
        _errorMessage = 'Tài khoản đã hết hạn hoặc chưa có hiệu lực';
        notifyListeners();
        return false;
      }

      // Check current status
      _isInside = await _firestoreService.isUserInside(user.id);
      _scannedUser = user;
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
    required GateModel gate,
    required String guardId,
    required String guardName,
    double? temperature,
    String? note,
  }) async {
    if (_scannedUser == null) {
      _errorMessage = 'Không có thông tin người dùng';
      notifyListeners();
      return false;
    }

    // Check if already inside
    if (_isInside) {
      _errorMessage = 'Người dùng đã check-in trước đó';
      notifyListeners();
      return false;
    }

    // Check if gate allows check-in
    if (!gate.canCheckIn) {
      _errorMessage = 'Cổng này không hỗ trợ check-in';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final log = AccessLogModel(
        id: '',
        userId: _scannedUser!.id,
        userName: _scannedUser!.fullName,
        userPhotoUrl: _scannedUser!.photoUrl,
        type: AppConstants.accessTypeCheckIn,
        timestamp: DateTime.now(),
        gateId: gate.id,
        gateName: gate.gateName,
        scannedBy: guardId,
        scannedByName: guardName,
        temperature: temperature,
        note: note,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAccessLog(log);

      _isLoading = false;
      _isInside = true;
      _successMessage = 'Check-in thành công: ${_scannedUser!.fullName}';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi check-in: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Perform check-out
  Future<bool> performCheckOut({
    required GateModel gate,
    required String guardId,
    required String guardName,
    String? note,
  }) async {
    if (_scannedUser == null) {
      _errorMessage = 'Không có thông tin người dùng';
      notifyListeners();
      return false;
    }

    // Check if user is inside
    if (!_isInside) {
      _errorMessage = 'Người dùng chưa check-in';
      notifyListeners();
      return false;
    }

    // Check if gate allows check-out
    if (!gate.canCheckOut) {
      _errorMessage = 'Cổng này không hỗ trợ check-out';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final log = AccessLogModel(
        id: '',
        userId: _scannedUser!.id,
        userName: _scannedUser!.fullName,
        userPhotoUrl: _scannedUser!.photoUrl,
        type: AppConstants.accessTypeCheckOut,
        timestamp: DateTime.now(),
        gateId: gate.id,
        gateName: gate.gateName,
        scannedBy: guardId,
        scannedByName: guardName,
        note: note,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAccessLog(log);

      _isLoading = false;
      _isInside = false;
      _successMessage = 'Check-out thành công: ${_scannedUser!.fullName}';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi check-out: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear scan data
  void clearScanData() {
    _scannedUser = null;
    _lastScanResult = null;
    _errorMessage = null;
    _successMessage = null;
    _isInside = false;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Get recommended action based on current status
  String getRecommendedAction() {
    if (_isInside) {
      return 'Check-out';
    }
    return 'Check-in';
  }

  /// Get status text
  String getStatusText() {
    if (_scannedUser == null) return 'Chưa quét';
    return _isInside ? 'Đang ở trong' : 'Đang ở ngoài';
  }

  /// Refresh data
  void refresh() {
    if (_currentUserPhone != null && _currentUserPhone!.isNotEmpty) {
      _loadAccessHistoryByPhone();
      _checkCurrentStatusByPhone();
    }
  }

  /// Clear all and cancel subscriptions
  void clear() {
    _historySubscription?.cancel();
    _currentUserId = null;
    _currentUserPhone = null;
    _currentUserType = null;
    _accessHistory = [];
    _lastAccessLog = null;
    _isInside = false;
    _scannedUser = null;
    _lastScanResult = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
}