import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/constants/app_constants.dart';
import '../models/gate_access_registration_model.dart';

/// Service for generating and validating Gate Access QR codes
///
/// QR Format: GATE_ACCESS:registrationId:expectedDate:timeFrom:timeTo:timestamp:checksum
///
/// Example: GATE_ACCESS:abc123:20260123:0800:1700:1737628800000:a1b2c3d4
///
/// Components:
/// - GATE_ACCESS: Prefix to identify QR type
/// - registrationId: Unique registration ID from Firestore
/// - expectedDate: Registration date (YYYYMMDD format)
/// - timeFrom: Start time (HHmm format, 0000 if all day)
/// - timeTo: End time (HHmm format, 2359 if all day)
/// - timestamp: QR generation timestamp (milliseconds)
/// - checksum: Security hash (first 8 chars of SHA256)
class GateAccessQRService {
  static const String _qrPrefix = 'GATE_ACCESS';
  static const String _secretKey = 'gate_access_qr_secret_2024';

  /// Generate QR code string for a registration
  static String generateQRCode({
    required String registrationId,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    bool isMultipleDays = false,
    DateTime? endDate,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Format date as YYYYMMDD
    final dateStr = _formatDate(expectedDate);

    // Format time as HHmm (0000 and 2359 for all day)
    final timeFromStr = expectedTimeFrom != null
        ? _formatTime(expectedTimeFrom)
        : '0000';
    final timeToStr = expectedTimeTo != null
        ? _formatTime(expectedTimeTo)
        : '2359';

    // End date for multiple days registration (YYYYMMDD or 0 if single day)
    final endDateStr = isMultipleDays && endDate != null
        ? _formatDate(endDate)
        : '0';

    // Generate checksum
    final checksum = _generateChecksum(
      registrationId,
      dateStr,
      timeFromStr,
      timeToStr,
      endDateStr,
      timestamp,
    );

    // Build QR string
    return '$_qrPrefix:$registrationId:$dateStr:$timeFromStr:$timeToStr:$endDateStr:$timestamp:$checksum';
  }

  /// Parse and validate QR code string
  /// Returns GateAccessQRResult with parsed data or error
  static GateAccessQRResult parseQRCode(String qrData) {
    try {
      final parts = qrData.split(':');

      // Validate format (must have 8 parts)
      if (parts.length != 8) {
        return GateAccessQRResult.invalid('Mã QR không đúng định dạng');
      }

      final prefix = parts[0];
      final registrationId = parts[1];
      final dateStr = parts[2];
      final timeFromStr = parts[3];
      final timeToStr = parts[4];
      final endDateStr = parts[5];
      final timestampStr = parts[6];
      final checksum = parts[7];

      // Validate prefix
      if (prefix != _qrPrefix) {
        return GateAccessQRResult.invalid('Mã QR không phải của hệ thống');
      }

      // Validate timestamp
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) {
        return GateAccessQRResult.invalid('Mã QR không hợp lệ: timestamp');
      }

      // Validate checksum
      final expectedChecksum = _generateChecksum(
        registrationId,
        dateStr,
        timeFromStr,
        timeToStr,
        endDateStr,
        timestamp,
      );

      if (checksum != expectedChecksum) {
        return GateAccessQRResult.invalid('Mã QR bị giả mạo hoặc không hợp lệ');
      }

      // Parse date
      final expectedDate = _parseDate(dateStr);
      if (expectedDate == null) {
        return GateAccessQRResult.invalid('Ngày đăng ký không hợp lệ');
      }

      // Parse times
      final timeFrom = _parseTime(timeFromStr);
      final timeTo = _parseTime(timeToStr);

      // Parse end date for multiple days
      final isMultipleDays = endDateStr != '0';
      final endDate = isMultipleDays ? _parseDate(endDateStr) : null;

      // QR generation time
      final qrGeneratedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

      return GateAccessQRResult.valid(
        registrationId: registrationId,
        expectedDate: expectedDate,
        expectedTimeFrom: timeFrom,
        expectedTimeTo: timeTo,
        isMultipleDays: isMultipleDays,
        endDate: endDate,
        qrGeneratedAt: qrGeneratedAt,
      );
    } catch (e) {
      return GateAccessQRResult.invalid('Không thể đọc mã QR: ${e.toString()}');
    }
  }

  /// Validate a registration against parsed QR data
  static GateAccessValidationResult validateRegistration(
    GateAccessRegistrationModel registration, {
    required bool isCheckIn,
  }) {
    // 1. Check status
    if (registration.status != AppConstants.statusApproved) {
      switch (registration.status) {
        case 'pending':
          return GateAccessValidationResult.invalid('Đăng ký chưa được duyệt');
        case 'rejected':
          return GateAccessValidationResult.invalid('Đăng ký đã bị từ chối');
        case 'cancelled':
          return GateAccessValidationResult.invalid('Đăng ký đã bị hủy');
        case 'expired':
          return GateAccessValidationResult.invalid('Đăng ký đã hết hạn');
        case 'used':
          return GateAccessValidationResult.invalid('Mã QR đã được sử dụng');
        default:
          return GateAccessValidationResult.invalid('Trạng thái đăng ký không hợp lệ: ${registration.status}');
      }
    }

    // 2. Check QR expiry
    if (registration.qrExpiresAt != null) {
      if (DateTime.now().isAfter(registration.qrExpiresAt!)) {
        return GateAccessValidationResult.invalid('Mã QR đã hết hạn');
      }
    }

    // 3. Check date validity
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      registration.expectedDate.year,
      registration.expectedDate.month,
      registration.expectedDate.day,
    );

    if (registration.isMultipleDays && registration.endDate != null) {
      // Multiple days registration
      final endDate = DateTime(
        registration.endDate!.year,
        registration.endDate!.month,
        registration.endDate!.day,
      );

      if (today.isBefore(startDate)) {
        return GateAccessValidationResult.invalid(
          'Đăng ký chưa đến ngày hiệu lực\n(${registration.expectedDateDisplay})'
        );
      }

      if (today.isAfter(endDate)) {
        return GateAccessValidationResult.invalid(
          'Đăng ký đã hết hạn\n(${registration.expectedDateDisplay})'
        );
      }
    } else {
      // Single day registration
      if (today.isBefore(startDate)) {
        return GateAccessValidationResult.invalid(
          'Không phải ngày đăng ký\nNgày đăng ký: ${registration.expectedDateDisplay}'
        );
      }

      if (today.isAfter(startDate)) {
        return GateAccessValidationResult.invalid(
          'Đăng ký đã quá hạn\nNgày đăng ký: ${registration.expectedDateDisplay}'
        );
      }
    }

    // 4. Check time validity (optional, only if times are specified)
    if (registration.expectedTimeFrom != null && registration.expectedTimeTo != null) {
      final currentMinutes = now.hour * 60 + now.minute;
      final fromMinutes = registration.expectedTimeFrom!.hour * 60 + registration.expectedTimeFrom!.minute;
      final toMinutes = registration.expectedTimeTo!.hour * 60 + registration.expectedTimeTo!.minute;

      // Allow 30 minutes early/late buffer
      const bufferMinutes = 30;

      if (currentMinutes < fromMinutes - bufferMinutes) {
        return GateAccessValidationResult.invalid(
          'Chưa đến giờ đăng ký\nGiờ cho phép: ${registration.expectedTimeDisplay}'
        );
      }

      if (currentMinutes > toMinutes + bufferMinutes) {
        return GateAccessValidationResult.invalid(
          'Đã quá giờ đăng ký\nGiờ cho phép: ${registration.expectedTimeDisplay}'
        );
      }
    }

    // 5. Check access type validity
    if (isCheckIn) {
      // Check-in validation
      if (registration.accessType == 'exit') {
        return GateAccessValidationResult.invalid('Đăng ký này chỉ dành cho ra cổng');
      }

      if (registration.hasCheckedIn && !registration.hasCheckedOut) {
        return GateAccessValidationResult.invalid(
          'Khách đã check-in trước đó\nVui lòng check-out trước khi check-in lại'
        );
      }

      // For single entry only (not multiple days), check if already used
      if (!registration.isMultipleDays && registration.hasCheckedIn && registration.hasCheckedOut) {
        return GateAccessValidationResult.invalid('Đăng ký này đã được sử dụng');
      }
    } else {
      // Check-out validation
      if (registration.accessType == 'entry') {
        return GateAccessValidationResult.invalid('Đăng ký này chỉ dành cho vào cổng');
      }

      if (!registration.hasCheckedIn) {
        return GateAccessValidationResult.invalid('Khách chưa check-in\nVui lòng check-in trước');
      }

      if (registration.hasCheckedOut) {
        return GateAccessValidationResult.invalid('Khách đã check-out trước đó');
      }
    }

    // All validations passed
    return GateAccessValidationResult.valid(
      canCheckIn: !registration.isCurrentlyInside && registration.accessType != 'exit',
      canCheckOut: registration.isCurrentlyInside && registration.accessType != 'entry',
    );
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.length != 8) return null;
    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseTime(String timeStr) {
    if (timeStr.length != 4) return null;
    try {
      final hour = int.parse(timeStr.substring(0, 2));
      final minute = int.parse(timeStr.substring(2, 4));
      return DateTime(2000, 1, 1, hour, minute); // Only time matters
    } catch (e) {
      return null;
    }
  }

  static String _generateChecksum(
    String registrationId,
    String dateStr,
    String timeFromStr,
    String timeToStr,
    String endDateStr,
    int timestamp,
  ) {
    final data = '$registrationId:$dateStr:$timeFromStr:$timeToStr:$endDateStr:$timestamp:$_secretKey';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }
}

/// Result of parsing QR code
class GateAccessQRResult {
  final bool isValid;
  final String? registrationId;
  final DateTime? expectedDate;
  final DateTime? expectedTimeFrom;
  final DateTime? expectedTimeTo;
  final bool isMultipleDays;
  final DateTime? endDate;
  final DateTime? qrGeneratedAt;
  final String? errorMessage;

  GateAccessQRResult._({
    required this.isValid,
    this.registrationId,
    this.expectedDate,
    this.expectedTimeFrom,
    this.expectedTimeTo,
    this.isMultipleDays = false,
    this.endDate,
    this.qrGeneratedAt,
    this.errorMessage,
  });

  factory GateAccessQRResult.valid({
    required String registrationId,
    required DateTime expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    bool isMultipleDays = false,
    DateTime? endDate,
    required DateTime qrGeneratedAt,
  }) {
    return GateAccessQRResult._(
      isValid: true,
      registrationId: registrationId,
      expectedDate: expectedDate,
      expectedTimeFrom: expectedTimeFrom,
      expectedTimeTo: expectedTimeTo,
      isMultipleDays: isMultipleDays,
      endDate: endDate,
      qrGeneratedAt: qrGeneratedAt,
    );
  }

  factory GateAccessQRResult.invalid(String errorMessage) {
    return GateAccessQRResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result of validating registration
class GateAccessValidationResult {
  final bool isValid;
  final bool canCheckIn;
  final bool canCheckOut;
  final String? errorMessage;

  GateAccessValidationResult._({
    required this.isValid,
    this.canCheckIn = false,
    this.canCheckOut = false,
    this.errorMessage,
  });

  factory GateAccessValidationResult.valid({
    required bool canCheckIn,
    required bool canCheckOut,
  }) {
    return GateAccessValidationResult._(
      isValid: true,
      canCheckIn: canCheckIn,
      canCheckOut: canCheckOut,
    );
  }

  factory GateAccessValidationResult.invalid(String errorMessage) {
    return GateAccessValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
