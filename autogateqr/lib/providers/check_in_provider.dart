import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/access_log_model.dart';
import '../models/gate_model.dart';
import '../services/firestore_service.dart';
import '../services/qr_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for guard/scanner app to handle person check-in/check-out
class CheckInProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State
  List<AccessLogModel> _todayLogs = [];
  List<GateModel> _gates = [];
  GateModel? _selectedGate;

  // Scan result
  UserModel? _scannedUser;
  QRValidationResult? _lastScanResult;
  bool _isUserInside = false;
  AccessLogModel? _lastUserAccessLog;

  // Loading and messages
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  // Stats
  int _todayCheckIns = 0;
  int _todayCheckOuts = 0;
  int _currentPeopleInside = 0;

  // Subscriptions
  StreamSubscription? _logsSubscription;
  StreamSubscription? _gatesSubscription;

  // Getters
  List<AccessLogModel> get todayLogs => _todayLogs;
  List<GateModel> get gates => _gates;
  GateModel? get selectedGate => _selectedGate;
  UserModel? get scannedUser => _scannedUser;
  QRValidationResult? get lastScanResult => _lastScanResult;
  bool get isUserInside => _isUserInside;
  AccessLogModel? get lastUserAccessLog => _lastUserAccessLog;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get todayCheckIns => _todayCheckIns;
  int get todayCheckOuts => _todayCheckOuts;
  int get currentPeopleInside => _currentPeopleInside;

  // Can perform actions
  bool get canCheckIn => _scannedUser != null && !_isUserInside && _selectedGate != null && _selectedGate!.canCheckIn;
  bool get canCheckOut => _scannedUser != null && _isUserInside && _selectedGate != null && _selectedGate!.canCheckOut;

  /// Initialize provider
  void initialize() {
    _loadGates();
    _loadTodayLogs();
    _loadCurrentPeopleCount();
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

  /// Load today's access logs
  void _loadTodayLogs() {
    _logsSubscription?.cancel();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    _logsSubscription = FirebaseFirestore.instance
        .collection(AppConstants.accessLogsCollection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        _todayLogs = snapshot.docs
            .map((doc) => AccessLogModel.fromFirestore(doc))
            .toList();
        _updateStats();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không thể tải lịch sử hôm nay';
        notifyListeners();
      },
    );
  }

  /// Update statistics
  void _updateStats() {
    _todayCheckIns = _todayLogs.where((log) => log.isCheckIn).length;
    _todayCheckOuts = _todayLogs.where((log) => log.isCheckOut).length;

    // Calculate people currently inside
    final userStatus = <String, String>{};
    for (final log in _todayLogs.reversed) {
      userStatus[log.userId] = log.type;
    }
    _currentPeopleInside = userStatus.values
        .where((type) => type == AppConstants.accessTypeCheckIn)
        .length;
  }

  /// Load current people count
  Future<void> _loadCurrentPeopleCount() async {
    try {
      _currentPeopleInside = await _firestoreService.getCurrentPeopleCount();
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
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
      _scannedUser = null;
      _isUserInside = false;
      _lastUserAccessLog = null;
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

      // Validate user
      if (!user.canAccessGate) {
        _isLoading = false;
        if (!user.isActive) {
          _errorMessage = 'Tài khoản đã bị ${user.statusDisplay.toLowerCase()}';
        } else if (!user.isValidPeriod) {
          _errorMessage = 'Tài khoản đã hết hạn hoặc chưa có hiệu lực';
        } else {
          _errorMessage = 'Không được phép ra/vào';
        }
        notifyListeners();
        return false;
      }

      // Get last access log and determine current status
      final lastLog = await _firestoreService.getLastAccessLog(user.id);
      _lastUserAccessLog = lastLog;

      // Check if user is currently inside (last action was check-in today)
      if (lastLog != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final logDate = DateTime(lastLog.timestamp.year, lastLog.timestamp.month, lastLog.timestamp.day);
        _isUserInside = logDate == today && lastLog.isCheckIn;
      }

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

    if (_selectedGate == null) {
      _errorMessage = 'Vui lòng chọn cổng';
      notifyListeners();
      return false;
    }

    if (_isUserInside) {
      _errorMessage = '${_scannedUser!.fullName} đã check-in trước đó';
      notifyListeners();
      return false;
    }

    if (!_selectedGate!.canCheckIn) {
      _errorMessage = 'Cổng này không hỗ trợ check-in';
      notifyListeners();
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final log = AccessLogModel(
        id: '',
        userId: _scannedUser!.id,
        userName: _scannedUser!.fullName,
        userPhotoUrl: _scannedUser!.photoUrl,
        type: AppConstants.accessTypeCheckIn,
        timestamp: DateTime.now(),
        gateId: _selectedGate!.id,
        gateName: _selectedGate!.gateName,
        scannedBy: guardId,
        scannedByName: guardName,
        temperature: temperature,
        note: note,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAccessLog(log);

      _isProcessing = false;
      _isUserInside = true;
      _successMessage = 'Check-in thành công: ${_scannedUser!.fullName}';
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
  }) async {
    if (_scannedUser == null) {
      _errorMessage = 'Không có thông tin người dùng';
      notifyListeners();
      return false;
    }

    if (_selectedGate == null) {
      _errorMessage = 'Vui lòng chọn cổng';
      notifyListeners();
      return false;
    }

    if (!_isUserInside) {
      _errorMessage = '${_scannedUser!.fullName} chưa check-in';
      notifyListeners();
      return false;
    }

    if (!_selectedGate!.canCheckOut) {
      _errorMessage = 'Cổng này không hỗ trợ check-out';
      notifyListeners();
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final log = AccessLogModel(
        id: '',
        userId: _scannedUser!.id,
        userName: _scannedUser!.fullName,
        userPhotoUrl: _scannedUser!.photoUrl,
        type: AppConstants.accessTypeCheckOut,
        timestamp: DateTime.now(),
        gateId: _selectedGate!.id,
        gateName: _selectedGate!.gateName,
        scannedBy: guardId,
        scannedByName: guardName,
        note: note,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAccessLog(log);

      _isProcessing = false;
      _isUserInside = false;
      _successMessage = 'Check-out thành công: ${_scannedUser!.fullName}';
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
    _scannedUser = null;
    _lastScanResult = null;
    _lastUserAccessLog = null;
    _isUserInside = false;
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

  /// Get status text for scanned user
  String getStatusText() {
    if (_scannedUser == null) return 'Chưa quét';
    return _isUserInside ? 'Đang ở trong nhà máy' : 'Đang ở ngoài nhà máy';
  }

  /// Get recommended action
  String getRecommendedAction() {
    if (_scannedUser == null) return '';
    return _isUserInside ? 'Check-out' : 'Check-in';
  }

  /// Clear all data
  void clear() {
    _logsSubscription?.cancel();
    _gatesSubscription?.cancel();
    _todayLogs = [];
    _gates = [];
    _selectedGate = null;
    _scannedUser = null;
    _lastScanResult = null;
    _isUserInside = false;
    _lastUserAccessLog = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _gatesSubscription?.cancel();
    super.dispose();
  }
}
