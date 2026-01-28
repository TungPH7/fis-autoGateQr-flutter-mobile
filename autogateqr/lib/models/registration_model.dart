import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverInfo {
  final String name;
  final String phone;
  final String? license;
  final String? idCard;

  DriverInfo({
    required this.name,
    required this.phone,
    this.license,
    this.idCard,
  });

  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      license: map['license'],
      idCard: map['idCard'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'license': license,
      'idCard': idCard,
    };
  }
}

class CargoInfo {
  final String? description;
  final double? weight;
  final String? containerNumber;
  final String? sealNumber;

  CargoInfo({
    this.description,
    this.weight,
    this.containerNumber,
    this.sealNumber,
  });

  factory CargoInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CargoInfo();
    return CargoInfo(
      description: map['description'],
      weight: (map['weight'] as num?)?.toDouble(),
      containerNumber: map['containerNumber'],
      sealNumber: map['sealNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'weight': weight,
      'containerNumber': containerNumber,
      'sealNumber': sealNumber,
    };
  }
}

class RegistrationModel {
  final String id;
  final String registrationType; // 'entry', 'exit', 'both'
  final String? companyId;
  final String? companyName;
  final String userId;
  final String? userFullName;
  final String? vehicleId;
  final String? plateNumber;
  final String? vehicleType;
  final DriverInfo driverInfo;
  final String visitPurpose;
  final String? visitLocation;
  final DateTime expectedDate;
  final DateTime? expectedTimeFrom;
  final DateTime? expectedTimeTo;
  final CargoInfo? cargoInfo;
  final String status; // 'pending', 'approved', 'rejected', 'completed', 'expired'
  final String? qrCode;
  final String? qrCodeUrl;
  final DateTime? qrGeneratedAt;
  final DateTime? qrExpiresAt;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final List<String> attachments;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RegistrationModel({
    required this.id,
    required this.registrationType,
    this.companyId,
    this.companyName,
    required this.userId,
    this.userFullName,
    this.vehicleId,
    this.plateNumber,
    this.vehicleType,
    required this.driverInfo,
    required this.visitPurpose,
    this.visitLocation,
    required this.expectedDate,
    this.expectedTimeFrom,
    this.expectedTimeTo,
    this.cargoInfo,
    required this.status,
    this.qrCode,
    this.qrCodeUrl,
    this.qrGeneratedAt,
    this.qrExpiresAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.attachments = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistrationModel(
      id: doc.id,
      registrationType: data['registrationType'] ?? 'both',
      companyId: data['companyId'],
      companyName: data['companyName'],
      userId: data['userId'] ?? '',
      userFullName: data['userFullName'],
      vehicleId: data['vehicleId'],
      plateNumber: data['plateNumber'],
      vehicleType: data['vehicleType'],
      driverInfo: DriverInfo.fromMap(data['driverInfo'] ?? {}),
      visitPurpose: data['visitPurpose'] ?? '',
      visitLocation: data['visitLocation'],
      expectedDate: (data['expectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedTimeFrom: (data['expectedTimeFrom'] as Timestamp?)?.toDate(),
      expectedTimeTo: (data['expectedTimeTo'] as Timestamp?)?.toDate(),
      cargoInfo: CargoInfo.fromMap(data['cargoInfo']),
      status: data['status'] ?? 'pending',
      qrCode: data['qrCode'],
      qrCodeUrl: data['qrCodeUrl'],
      qrGeneratedAt: (data['qrGeneratedAt'] as Timestamp?)?.toDate(),
      qrExpiresAt: (data['qrExpiresAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      approvedByName: data['approvedByName'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      attachments: List<String>.from(data['attachments'] ?? []),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'registrationType': registrationType,
      'companyId': companyId,
      'companyName': companyName,
      'userId': userId,
      'userFullName': userFullName,
      'vehicleId': vehicleId,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType,
      'driverInfo': driverInfo.toMap(),
      'visitPurpose': visitPurpose,
      'visitLocation': visitLocation,
      'expectedDate': Timestamp.fromDate(expectedDate),
      'expectedTimeFrom': expectedTimeFrom != null ? Timestamp.fromDate(expectedTimeFrom!) : null,
      'expectedTimeTo': expectedTimeTo != null ? Timestamp.fromDate(expectedTimeTo!) : null,
      'cargoInfo': cargoInfo?.toMap(),
      'status': status,
      'qrCode': qrCode,
      'qrCodeUrl': qrCodeUrl,
      'qrGeneratedAt': qrGeneratedAt != null ? Timestamp.fromDate(qrGeneratedAt!) : null,
      'qrExpiresAt': qrExpiresAt != null ? Timestamp.fromDate(qrExpiresAt!) : null,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'attachments': attachments,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RegistrationModel copyWith({
    String? id,
    String? registrationType,
    String? companyId,
    String? companyName,
    String? userId,
    String? userFullName,
    String? vehicleId,
    String? plateNumber,
    String? vehicleType,
    DriverInfo? driverInfo,
    String? visitPurpose,
    String? visitLocation,
    DateTime? expectedDate,
    DateTime? expectedTimeFrom,
    DateTime? expectedTimeTo,
    CargoInfo? cargoInfo,
    String? status,
    String? qrCode,
    String? qrCodeUrl,
    DateTime? qrGeneratedAt,
    DateTime? qrExpiresAt,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    List<String>? attachments,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      registrationType: registrationType ?? this.registrationType,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      vehicleId: vehicleId ?? this.vehicleId,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverInfo: driverInfo ?? this.driverInfo,
      visitPurpose: visitPurpose ?? this.visitPurpose,
      visitLocation: visitLocation ?? this.visitLocation,
      expectedDate: expectedDate ?? this.expectedDate,
      expectedTimeFrom: expectedTimeFrom ?? this.expectedTimeFrom,
      expectedTimeTo: expectedTimeTo ?? this.expectedTimeTo,
      cargoInfo: cargoInfo ?? this.cargoInfo,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      qrGeneratedAt: qrGeneratedAt ?? this.qrGeneratedAt,
      qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';

  bool get hasValidQR {
    if (qrCode == null || qrExpiresAt == null) return false;
    return DateTime.now().isBefore(qrExpiresAt!);
  }

  bool get isQRExpired {
    if (qrExpiresAt == null) return false;
    return DateTime.now().isAfter(qrExpiresAt!);
  }

  // Generate QR data as JSON string
  String generateQRData() {
    final qrData = {
      'registrationId': id,
      'vehiclePlate': plateNumber,
      'companyName': companyName,
      'driverName': driverInfo.name,
      'expectedDate': expectedDate.toIso8601String(),
      'qrVersion': '1.0',
    };
    return jsonEncode(qrData);
  }

  // Parse QR data
  static Map<String, dynamic>? parseQRData(String qrString) {
    try {
      return jsonDecode(qrString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
