import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Model for gate access registration requests
/// Flow: User registers -> Admin approves -> QR activated
class GateAccessRegistrationModel {
  final String id;
  final String visitorType; // 'employee', 'contractor', 'visitor'

  // Personal information
  final String fullName;
  final String phone;
  final String? email;
  final String? address;
  final String? idCard; // CCCD/CMND
  final String? companyName;
  final String? photoUrl;

  // For registered users (app users)
  final String? userId; // null if registered by guard

  // Time information
  final DateTime expectedDate;
  final DateTime? expectedTimeFrom;
  final DateTime? expectedTimeTo;
  final String accessType; // 'entry', 'exit', 'both'

  // Visit purpose
  final String purpose;
  final String? visitDepartment; // Phòng ban đến làm việc
  final String? hostName; // Làm việc với ai
  final String? hostPhone; // SĐT người tiếp đón

  // Status & approval
  final String status; // 'pending', 'approved', 'rejected', 'expired', 'used'
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;

  // QR Code
  final String? qrCode;
  final DateTime? qrExpiresAt;

  // Check-in/out tracking
  final DateTime? actualCheckInTime;
  final DateTime? actualCheckOutTime;
  final String? checkInGateId;
  final String? checkOutGateId;
  final String? checkInGuardId;
  final String? checkOutGuardId;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // Guard ID if registered by guard

  // Vehicle information
  final String? vehiclePlate; // Biển số xe
  final String? vehicleType; // 'car', 'motorcycle', null

  // Additional info
  final String? note;
  final List<String>? attachments;

  // Guard holds ID card
  final bool idCardHeldByGuard; // Bảo vệ giữ CCCD

  // Địa chỉ/Công ty (gộp)
  final String? addressOrCompany; // Địa chỉ hoặc Tên công ty

  // Thẻ ra vào được cấp bởi bảo vệ
  final String? accessCardNumber; // Mã thẻ ra vào được cấp
  final bool accessCardIssued; // Đã cấp thẻ ra vào chưa

  // Đăng ký nhiều ngày
  final bool isMultipleDays; // Đăng ký sử dụng nhiều ngày
  final DateTime? endDate; // Ngày kết thúc (nếu đăng ký nhiều ngày)

  GateAccessRegistrationModel({
    required this.id,
    this.visitorType = 'visitor',
    required this.fullName,
    required this.phone,
    this.email,
    this.address,
    this.idCard,
    this.companyName,
    this.photoUrl,
    this.userId,
    required this.expectedDate,
    this.expectedTimeFrom,
    this.expectedTimeTo,
    this.accessType = 'both',
    required this.purpose,
    this.visitDepartment,
    this.hostName,
    this.hostPhone,
    this.status = 'pending',
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.qrCode,
    this.qrExpiresAt,
    this.actualCheckInTime,
    this.actualCheckOutTime,
    this.checkInGateId,
    this.checkOutGateId,
    this.checkInGuardId,
    this.checkOutGuardId,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.vehiclePlate,
    this.vehicleType,
    this.note,
    this.attachments,
    this.idCardHeldByGuard = false,
    this.addressOrCompany,
    this.accessCardNumber,
    this.accessCardIssued = false,
    this.isMultipleDays = false,
    this.endDate,
  });

  factory GateAccessRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GateAccessRegistrationModel(
      id: doc.id,
      visitorType: data['visitorType'] ?? 'visitor',
      fullName: data['fullName'] ?? data['userFullName'] ?? '',
      phone: data['phone'] ?? data['userPhone'] ?? '',
      email: data['email'] ?? data['userEmail'],
      address: data['address'],
      idCard: data['idCard'],
      companyName: data['companyName'],
      photoUrl: data['photoUrl'] ?? data['userPhotoUrl'],
      userId: data['userId'],
      expectedDate: (data['expectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedTimeFrom: (data['expectedTimeFrom'] as Timestamp?)?.toDate(),
      expectedTimeTo: (data['expectedTimeTo'] as Timestamp?)?.toDate(),
      accessType: data['accessType'] ?? 'both',
      purpose: data['purpose'] ?? '',
      visitDepartment: data['visitDepartment'] ?? data['hostDepartment'],
      hostName: data['hostName'],
      hostPhone: data['hostPhone'],
      status: data['status'] ?? 'pending',
      approvedBy: data['approvedBy'],
      approvedByName: data['approvedByName'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      qrCode: data['qrCode'],
      qrExpiresAt: (data['qrExpiresAt'] as Timestamp?)?.toDate(),
      actualCheckInTime: (data['actualCheckInTime'] as Timestamp?)?.toDate(),
      actualCheckOutTime: (data['actualCheckOutTime'] as Timestamp?)?.toDate(),
      checkInGateId: data['checkInGateId'],
      checkOutGateId: data['checkOutGateId'],
      checkInGuardId: data['checkInGuardId'],
      checkOutGuardId: data['checkOutGuardId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      vehiclePlate: data['vehiclePlate'],
      vehicleType: data['vehicleType'],
      note: data['note'],
      attachments: (data['attachments'] as List<dynamic>?)?.cast<String>(),
      idCardHeldByGuard: data['idCardHeldByGuard'] ?? false,
      addressOrCompany: data['addressOrCompany'],
      accessCardNumber: data['accessCardNumber'],
      accessCardIssued: data['accessCardIssued'] ?? false,
      isMultipleDays: data['isMultipleDays'] ?? false,
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitorType': visitorType,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'idCard': idCard,
      'companyName': companyName,
      'photoUrl': photoUrl,
      'userId': userId,
      'expectedDate': Timestamp.fromDate(expectedDate),
      'expectedTimeFrom': expectedTimeFrom != null ? Timestamp.fromDate(expectedTimeFrom!) : null,
      'expectedTimeTo': expectedTimeTo != null ? Timestamp.fromDate(expectedTimeTo!) : null,
      'accessType': accessType,
      'purpose': purpose,
      'visitDepartment': visitDepartment,
      'hostName': hostName,
      'hostPhone': hostPhone,
      'status': status,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'qrCode': qrCode,
      'qrExpiresAt': qrExpiresAt != null ? Timestamp.fromDate(qrExpiresAt!) : null,
      'actualCheckInTime': actualCheckInTime != null ? Timestamp.fromDate(actualCheckInTime!) : null,
      'actualCheckOutTime': actualCheckOutTime != null ? Timestamp.fromDate(actualCheckOutTime!) : null,
      'checkInGateId': checkInGateId,
      'checkOutGateId': checkOutGateId,
      'checkInGuardId': checkInGuardId,
      'checkOutGuardId': checkOutGuardId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'note': note,
      'attachments': attachments,
      'idCardHeldByGuard': idCardHeldByGuard,
      'addressOrCompany': addressOrCompany,
      'accessCardNumber': accessCardNumber,
      'accessCardIssued': accessCardIssued,
      'isMultipleDays': isMultipleDays,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  GateAccessRegistrationModel copyWith({
    String? id,
    String? visitorType,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? idCard,
    String? companyName,
    String? photoUrl,
    String? userId,
    DateTime? expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    String? accessType,
    String? purpose,
    String? visitDepartment,
    String? hostName,
    String? hostPhone,
    String? status,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? qrCode,
    DateTime? qrExpiresAt,
    DateTime? actualCheckInTime,
    DateTime? actualCheckOutTime,
    String? checkInGateId,
    String? checkOutGateId,
    String? checkInGuardId,
    String? checkOutGuardId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? vehiclePlate,
    String? vehicleType,
    String? note,
    List<String>? attachments,
    bool? idCardHeldByGuard,
    String? addressOrCompany,
    String? accessCardNumber,
    bool? accessCardIssued,
    bool? isMultipleDays,
    DateTime? endDate,
  }) {
    return GateAccessRegistrationModel(
      id: id ?? this.id,
      visitorType: visitorType ?? this.visitorType,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      idCard: idCard ?? this.idCard,
      companyName: companyName ?? this.companyName,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
      expectedDate: expectedDate ?? this.expectedDate,
      expectedTimeFrom: expectedTimeFrom ?? this.expectedTimeFrom,
      expectedTimeTo: expectedTimeTo ?? this.expectedTimeTo,
      accessType: accessType ?? this.accessType,
      purpose: purpose ?? this.purpose,
      visitDepartment: visitDepartment ?? this.visitDepartment,
      hostName: hostName ?? this.hostName,
      hostPhone: hostPhone ?? this.hostPhone,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      qrCode: qrCode ?? this.qrCode,
      qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
      actualCheckInTime: actualCheckInTime ?? this.actualCheckInTime,
      actualCheckOutTime: actualCheckOutTime ?? this.actualCheckOutTime,
      checkInGateId: checkInGateId ?? this.checkInGateId,
      checkOutGateId: checkOutGateId ?? this.checkOutGateId,
      checkInGuardId: checkInGuardId ?? this.checkInGuardId,
      checkOutGuardId: checkOutGuardId ?? this.checkOutGuardId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      note: note ?? this.note,
      attachments: attachments ?? this.attachments,
      idCardHeldByGuard: idCardHeldByGuard ?? this.idCardHeldByGuard,
      addressOrCompany: addressOrCompany ?? this.addressOrCompany,
      accessCardNumber: accessCardNumber ?? this.accessCardNumber,
      accessCardIssued: accessCardIssued ?? this.accessCardIssued,
      isMultipleDays: isMultipleDays ?? this.isMultipleDays,
      endDate: endDate ?? this.endDate,
    );
  }

  // Status helpers
  bool get isPending => status == AppConstants.statusPending;
  bool get isApproved => status == AppConstants.statusApproved;
  bool get isRejected => status == AppConstants.statusRejected;
  bool get isExpired => status == AppConstants.statusExpired;
  bool get isUsed => status == 'used';
  bool get isCancelled => status == 'cancelled';

  // Visitor type helpers
  bool get isEmployee => visitorType == 'employee';
  bool get isContractor => visitorType == 'contractor';
  bool get isVisitor => visitorType == 'visitor';

  // Registration source
  bool get isRegisteredByUser => userId != null && createdBy == null;
  bool get isRegisteredByGuard => createdBy != null;

  // QR validity
  bool get hasValidQR {
    if (!isApproved || qrCode == null) return false;
    if (qrExpiresAt != null && DateTime.now().isAfter(qrExpiresAt!)) return false;
    return true;
  }

  bool get isQRExpired {
    if (qrExpiresAt == null) return false;
    return DateTime.now().isAfter(qrExpiresAt!);
  }

  // Check-in/out status
  bool get hasCheckedIn => actualCheckInTime != null;
  bool get hasCheckedOut => actualCheckOutTime != null;
  bool get isCurrentlyInside => hasCheckedIn && !hasCheckedOut;

  // Check if registration is valid for today (accounts for multiple days)
  bool get isForToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);

    if (isMultipleDays && endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return !today.isBefore(startDate) && !today.isAfter(end);
    }

    return expectedDate.year == now.year &&
        expectedDate.month == now.month &&
        expectedDate.day == now.day;
  }

  // Check if registration date has passed (accounts for multiple days)
  bool get isDatePassed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isMultipleDays && endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return today.isAfter(end);
    }

    final regDate = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
    return regDate.isBefore(today);
  }

  // Display helpers
  String get visitorTypeDisplay {
    switch (visitorType) {
      case 'employee':
        return 'Nhân viên';
      case 'contractor':
        return 'Nhà thầu';
      case 'visitor':
        return 'Khách/Nhà thầu';
      default:
        return visitorType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'expired':
        return 'Hết hạn';
      case 'used':
        return 'Đã sử dụng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get accessTypeDisplay {
    switch (accessType) {
      case 'entry':
        return 'Vào';
      case 'exit':
        return 'Ra';
      case 'both':
        return 'Ra/Vào';
      default:
        return accessType;
    }
  }

  String? get vehicleTypeDisplay {
    if (vehicleType == null) return null;
    switch (vehicleType) {
      case 'car':
        return 'Ô tô';
      case 'motorcycle':
        return 'Xe máy';
      default:
        return vehicleType;
    }
  }

  bool get hasVehicle => vehiclePlate != null && vehiclePlate!.isNotEmpty;

  String get expectedDateDisplay {
    final startStr = '${expectedDate.day.toString().padLeft(2, '0')}/${expectedDate.month.toString().padLeft(2, '0')}/${expectedDate.year}';
    if (isMultipleDays && endDate != null) {
      final endStr = '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}';
      return '$startStr - $endStr';
    }
    return startStr;
  }

  String get expectedTimeDisplay {
    if (expectedTimeFrom == null && expectedTimeTo == null) return 'Cả ngày';
    final from = expectedTimeFrom != null
        ? '${expectedTimeFrom!.hour.toString().padLeft(2, '0')}:${expectedTimeFrom!.minute.toString().padLeft(2, '0')}'
        : '00:00';
    final to = expectedTimeTo != null
        ? '${expectedTimeTo!.hour.toString().padLeft(2, '0')}:${expectedTimeTo!.minute.toString().padLeft(2, '0')}'
        : '23:59';
    return '$from - $to';
  }

  String get createdAtDisplay {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String? get idCardMasked {
    if (idCard == null || idCard!.length < 4) return idCard;
    return '****${idCard!.substring(idCard!.length - 4)}';
  }
}
