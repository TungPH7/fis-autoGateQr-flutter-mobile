import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInOutModel {
  final String id;
  final String registrationId;
  final String? vehicleId;
  final String plateNumber;
  final String? userId;
  final String? userFullName;
  final String? companyName;
  final String gateId;
  final String? gateName;
  final String guardId;
  final String? guardName;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInPlateNumber;
  final String? checkInImage;
  final GeoPoint? checkInLocation;
  final String? checkOutPlateNumber;
  final String? checkOutImage;
  final GeoPoint? checkOutLocation;
  final int? durationMinutes;
  final String? notes;
  final String status; // 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime? updatedAt;

  CheckInOutModel({
    required this.id,
    required this.registrationId,
    this.vehicleId,
    required this.plateNumber,
    this.userId,
    this.userFullName,
    this.companyName,
    required this.gateId,
    this.gateName,
    required this.guardId,
    this.guardName,
    this.checkInTime,
    this.checkOutTime,
    this.checkInPlateNumber,
    this.checkInImage,
    this.checkInLocation,
    this.checkOutPlateNumber,
    this.checkOutImage,
    this.checkOutLocation,
    this.durationMinutes,
    this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory CheckInOutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckInOutModel(
      id: doc.id,
      registrationId: data['registrationId'] ?? '',
      vehicleId: data['vehicleId'],
      plateNumber: data['plateNumber'] ?? '',
      userId: data['userId'],
      userFullName: data['userFullName'],
      companyName: data['companyName'],
      gateId: data['gateId'] ?? '',
      gateName: data['gateName'],
      guardId: data['guardId'] ?? '',
      guardName: data['guardName'],
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      checkInPlateNumber: data['checkInPlateNumber'],
      checkInImage: data['checkInImage'],
      checkInLocation: data['checkInLocation'] as GeoPoint?,
      checkOutPlateNumber: data['checkOutPlateNumber'],
      checkOutImage: data['checkOutImage'],
      checkOutLocation: data['checkOutLocation'] as GeoPoint?,
      durationMinutes: data['durationMinutes'],
      notes: data['notes'],
      status: data['status'] ?? 'in_progress',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'registrationId': registrationId,
      'vehicleId': vehicleId,
      'plateNumber': plateNumber,
      'userId': userId,
      'userFullName': userFullName,
      'companyName': companyName,
      'gateId': gateId,
      'gateName': gateName,
      'guardId': guardId,
      'guardName': guardName,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInPlateNumber': checkInPlateNumber,
      'checkInImage': checkInImage,
      'checkInLocation': checkInLocation,
      'checkOutPlateNumber': checkOutPlateNumber,
      'checkOutImage': checkOutImage,
      'checkOutLocation': checkOutLocation,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CheckInOutModel copyWith({
    String? id,
    String? registrationId,
    String? vehicleId,
    String? plateNumber,
    String? userId,
    String? userFullName,
    String? companyName,
    String? gateId,
    String? gateName,
    String? guardId,
    String? guardName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInPlateNumber,
    String? checkInImage,
    GeoPoint? checkInLocation,
    String? checkOutPlateNumber,
    String? checkOutImage,
    GeoPoint? checkOutLocation,
    int? durationMinutes,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckInOutModel(
      id: id ?? this.id,
      registrationId: registrationId ?? this.registrationId,
      vehicleId: vehicleId ?? this.vehicleId,
      plateNumber: plateNumber ?? this.plateNumber,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      companyName: companyName ?? this.companyName,
      gateId: gateId ?? this.gateId,
      gateName: gateName ?? this.gateName,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInPlateNumber: checkInPlateNumber ?? this.checkInPlateNumber,
      checkInImage: checkInImage ?? this.checkInImage,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutPlateNumber: checkOutPlateNumber ?? this.checkOutPlateNumber,
      checkOutImage: checkOutImage ?? this.checkOutImage,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;

  int calculateDuration() {
    if (checkInTime == null || checkOutTime == null) return 0;
    return checkOutTime!.difference(checkInTime!).inMinutes;
  }
}
