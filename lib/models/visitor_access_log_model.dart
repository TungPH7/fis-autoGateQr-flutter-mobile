import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for visitor check-in/check-out history logs
class VisitorAccessLogModel {
  final String id;
  final String registrationId; // Link to GateAccessRegistrationModel
  final String visitorName;
  final String visitorPhone;
  final String? visitorIdCard;
  final String visitorType; // 'visitor', 'employee', 'contractor'

  final String type; // 'check_in', 'check_out'
  final DateTime timestamp;

  final String? gateId;
  final String? gateName;
  final String guardId;
  final String? guardName;

  final String? purpose;
  final String? addressOrCompany;
  final bool idCardHeldByGuard;
  final String? accessCardNumber;

  final String? vehiclePlate;
  final String? vehicleType;

  final String? note;
  final DateTime createdAt;

  VisitorAccessLogModel({
    required this.id,
    required this.registrationId,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorIdCard,
    required this.visitorType,
    required this.type,
    required this.timestamp,
    this.gateId,
    this.gateName,
    required this.guardId,
    this.guardName,
    this.purpose,
    this.addressOrCompany,
    this.idCardHeldByGuard = false,
    this.accessCardNumber,
    this.vehiclePlate,
    this.vehicleType,
    this.note,
    required this.createdAt,
  });

  factory VisitorAccessLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitorAccessLogModel(
      id: doc.id,
      registrationId: data['registrationId'] ?? '',
      visitorName: data['visitorName'] ?? '',
      visitorPhone: data['visitorPhone'] ?? '',
      visitorIdCard: data['visitorIdCard'],
      visitorType: data['visitorType'] ?? 'visitor',
      type: data['type'] ?? 'check_in',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gateId: data['gateId'],
      gateName: data['gateName'],
      guardId: data['guardId'] ?? '',
      guardName: data['guardName'],
      purpose: data['purpose'],
      addressOrCompany: data['addressOrCompany'],
      idCardHeldByGuard: data['idCardHeldByGuard'] ?? false,
      accessCardNumber: data['accessCardNumber'],
      vehiclePlate: data['vehiclePlate'],
      vehicleType: data['vehicleType'],
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'registrationId': registrationId,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'visitorIdCard': visitorIdCard,
      'visitorType': visitorType,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'gateId': gateId,
      'gateName': gateName,
      'guardId': guardId,
      'guardName': guardName,
      'purpose': purpose,
      'addressOrCompany': addressOrCompany,
      'idCardHeldByGuard': idCardHeldByGuard,
      'accessCardNumber': accessCardNumber,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Type helpers
  bool get isCheckIn => type == 'check_in';
  bool get isCheckOut => type == 'check_out';

  // Display helpers
  String get typeDisplay => isCheckIn ? 'Check-in' : 'Check-out';

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

  String get timeDisplay {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get dateDisplay {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
  }

  String get dateTimeDisplay {
    return '$dateDisplay $timeDisplay';
  }
}
