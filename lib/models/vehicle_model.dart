import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String plateNumber;
  final String plateNumberNormalized;
  final String vehicleType;
  final String? brand;
  final String? model;
  final String? color;
  final String driverName;
  final String driverPhone;
  final String? driverLicense;
  final String? driverIdCard;
  final String? companyId;
  final String? companyName;
  final String ownerId;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String status; // 'active', 'inactive', 'blacklisted'
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.plateNumberNormalized,
    required this.vehicleType,
    this.brand,
    this.model,
    this.color,
    required this.driverName,
    required this.driverPhone,
    this.driverLicense,
    this.driverIdCard,
    this.companyId,
    this.companyName,
    required this.ownerId,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    required this.status,
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      plateNumber: data['plateNumber'] ?? '',
      plateNumberNormalized: data['plateNumberNormalized'] ?? '',
      vehicleType: data['vehicleType'] ?? 'car',
      brand: data['brand'],
      model: data['model'],
      color: data['color'],
      driverName: data['driverName'] ?? '',
      driverPhone: data['driverPhone'] ?? '',
      driverLicense: data['driverLicense'],
      driverIdCard: data['driverIdCard'],
      companyId: data['companyId'],
      companyName: data['companyName'],
      ownerId: data['ownerId'] ?? '',
      isApproved: data['isApproved'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plateNumber': plateNumber,
      'plateNumberNormalized': plateNumberNormalized,
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'color': color,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverLicense': driverLicense,
      'driverIdCard': driverIdCard,
      'companyId': companyId,
      'companyName': companyName,
      'ownerId': ownerId,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'status': status,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? plateNumber,
    String? plateNumberNormalized,
    String? vehicleType,
    String? brand,
    String? model,
    String? color,
    String? driverName,
    String? driverPhone,
    String? driverLicense,
    String? driverIdCard,
    String? companyId,
    String? companyName,
    String? ownerId,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      plateNumberNormalized: plateNumberNormalized ?? this.plateNumberNormalized,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicense: driverLicense ?? this.driverLicense,
      driverIdCard: driverIdCard ?? this.driverIdCard,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      ownerId: ownerId ?? this.ownerId,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayPlateNumber => plateNumber;
  bool get isActive => status == 'active';
  bool get isBlacklisted => status == 'blacklisted';

  static String getVehicleTypeName(String type) {
    switch (type) {
      case 'car':
        return 'Ô tô';
      case 'truck':
        return 'Xe tải';
      case 'container':
        return 'Xe container';
      case 'motorcycle':
        return 'Xe máy';
      default:
        return type;
    }
  }
}
