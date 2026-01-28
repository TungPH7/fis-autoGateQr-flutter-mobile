import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/constants/app_constants.dart';
import '../models/registration_model.dart';

/// Service for generating and validating dynamic QR codes
/// QR Format: userId|timestamp|checksum (for person-based access)
/// QR Format: registrationId (for legacy vehicle-based access)
class QRService {
  /// Generate dynamic QR data for a user (new person-based system)
  /// The QR data contains userId, current timestamp, and a checksum
  /// This QR should be regenerated every 30 seconds for security
  static String generateQRData(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final checksum = _generateChecksum(userId, timestamp);
    return '$userId|$timestamp|$checksum';
  }

  /// Generate QR data for registration (legacy vehicle-based system)
  static String generateRegistrationQRData(RegistrationModel registration) {
    return registration.id;
  }

  /// Parse and validate QR data
  /// Returns QRValidationResult with userId if valid, or error message if invalid
  static QRValidationResult parseQRData(String qrData) {
    try {
      final parts = qrData.split('|');

      // Validate format (must have 3 parts)
      if (parts.length != 3) {
        return QRValidationResult.invalid('Mã QR không hợp lệ');
      }

      final userId = parts[0];
      final timestamp = int.tryParse(parts[1]);
      final checksum = parts[2];

      // Validate timestamp parsing
      if (timestamp == null) {
        return QRValidationResult.invalid('Mã QR không hợp lệ: timestamp');
      }

      // Validate timestamp is within validity window (60 seconds)
      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final diffSeconds = now.difference(qrTime).inSeconds.abs();

      if (diffSeconds > AppConstants.qrValidityWindowSeconds) {
        return QRValidationResult.invalid(
          'Mã QR đã hết hạn (${diffSeconds}s > ${AppConstants.qrValidityWindowSeconds}s)',
        );
      }

      // Validate checksum
      final expectedChecksum = _generateChecksum(userId, timestamp);
      if (checksum != expectedChecksum) {
        return QRValidationResult.invalid('Mã QR không hợp lệ: checksum');
      }

      return QRValidationResult.valid(userId, qrTime);
    } catch (e) {
      return QRValidationResult.invalid('Không thể đọc mã QR: ${e.toString()}');
    }
  }

  /// Generate HMAC-SHA256 checksum (first 8 characters)
  static String _generateChecksum(String userId, int timestamp) {
    final data = '$userId:$timestamp:${AppConstants.qrSecretKey}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// Check if QR needs refresh based on generation time
  static bool needsRefresh(DateTime? generatedAt) {
    if (generatedAt == null) return true;
    final elapsed = DateTime.now().difference(generatedAt).inSeconds;
    return elapsed >= AppConstants.qrRefreshIntervalSeconds;
  }

  /// Get seconds until next refresh
  static int secondsUntilRefresh(DateTime? generatedAt) {
    if (generatedAt == null) return 0;
    final elapsed = DateTime.now().difference(generatedAt).inSeconds;
    final remaining = AppConstants.qrRefreshIntervalSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}

/// Result of QR validation
class QRValidationResult {
  final bool isValid;
  final String? userId;
  final DateTime? qrTimestamp;
  final String? errorMessage;

  QRValidationResult._({
    required this.isValid,
    this.userId,
    this.qrTimestamp,
    this.errorMessage,
  });

  factory QRValidationResult.valid(String userId, DateTime qrTimestamp) {
    return QRValidationResult._(
      isValid: true,
      userId: userId,
      qrTimestamp: qrTimestamp,
    );
  }

  factory QRValidationResult.invalid(String errorMessage) {
    return QRValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
