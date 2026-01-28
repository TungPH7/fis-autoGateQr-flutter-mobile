import 'package:cloud_firestore/cloud_firestore.dart';

class GateModel {
  final String id;
  final String gateCode;
  final String gateName;
  final String gateType; // 'in', 'out', 'both'
  final GeoPoint? location;
  final bool isActive;
  final List<String> assignedGuards;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GateModel({
    required this.id,
    required this.gateCode,
    required this.gateName,
    required this.gateType,
    this.location,
    this.isActive = true,
    this.assignedGuards = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory GateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GateModel(
      id: doc.id,
      gateCode: data['gateCode'] ?? '',
      gateName: data['gateName'] ?? '',
      gateType: data['gateType'] ?? 'both',
      location: data['location'] as GeoPoint?,
      isActive: data['isActive'] ?? true,
      assignedGuards: List<String>.from(data['assignedGuards'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gateCode': gateCode,
      'gateName': gateName,
      'gateType': gateType,
      'location': location,
      'isActive': isActive,
      'assignedGuards': assignedGuards,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  GateModel copyWith({
    String? id,
    String? gateCode,
    String? gateName,
    String? gateType,
    GeoPoint? location,
    bool? isActive,
    List<String>? assignedGuards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GateModel(
      id: id ?? this.id,
      gateCode: gateCode ?? this.gateCode,
      gateName: gateName ?? this.gateName,
      gateType: gateType ?? this.gateType,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      assignedGuards: assignedGuards ?? this.assignedGuards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get canCheckIn => gateType == 'in' || gateType == 'both';
  bool get canCheckOut => gateType == 'out' || gateType == 'both';

  String get gateTypeName {
    switch (gateType) {
      case 'in':
        return 'Cổng vào';
      case 'out':
        return 'Cổng ra';
      case 'both':
        return 'Cổng ra/vào';
      default:
        return gateType;
    }
  }
}
