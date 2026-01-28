import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/qr_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing dynamic QR code generation
/// Automatically refreshes QR code every 30 seconds for security
class QRProvider extends ChangeNotifier {
  String? _userId;
  String? _qrData;
  DateTime? _generatedAt;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = AppConstants.qrRefreshIntervalSeconds;
  bool _isActive = false;

  // Getters
  String? get qrData => _qrData;
  DateTime? get generatedAt => _generatedAt;
  int get secondsRemaining => _secondsRemaining;
  bool get isActive => _isActive;
  double get progress => _secondsRemaining / AppConstants.qrRefreshIntervalSeconds;

  /// Initialize QR provider with user ID
  void initialize(String userId) {
    _userId = userId;
    _generateQRCode();
    _startRefreshTimer();
    _isActive = true;
    notifyListeners();
  }

  /// Generate new QR code
  void _generateQRCode() {
    if (_userId == null) return;

    _qrData = QRService.generateQRData(_userId!);
    _generatedAt = DateTime.now();
    _secondsRemaining = AppConstants.qrRefreshIntervalSeconds;
    notifyListeners();
  }

  /// Start automatic refresh timer
  void _startRefreshTimer() {
    _stopTimers();

    // Timer to refresh QR every 30 seconds
    _refreshTimer = Timer.periodic(
      Duration(seconds: AppConstants.qrRefreshIntervalSeconds),
      (_) => _generateQRCode(),
    );

    // Timer to update countdown every second
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          notifyListeners();
        }
      },
    );
  }

  /// Stop all timers
  void _stopTimers() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer = null;
  }

  /// Manually refresh QR code
  void refresh() {
    _generateQRCode();
    _startRefreshTimer();
    notifyListeners();
  }

  /// Pause QR generation (when app goes to background)
  void pause() {
    _stopTimers();
    _isActive = false;
    notifyListeners();
  }

  /// Resume QR generation (when app comes to foreground)
  void resume() {
    if (_userId == null) return;

    // Check if QR needs refresh
    if (QRService.needsRefresh(_generatedAt)) {
      _generateQRCode();
    } else {
      // Update remaining time
      _secondsRemaining = QRService.secondsUntilRefresh(_generatedAt);
    }

    _startRefreshTimer();
    _isActive = true;
    notifyListeners();
  }

  /// Clear all data and stop timers
  void clear() {
    _stopTimers();
    _userId = null;
    _qrData = null;
    _generatedAt = null;
    _secondsRemaining = AppConstants.qrRefreshIntervalSeconds;
    _isActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
