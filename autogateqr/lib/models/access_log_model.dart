import 'package:cloud_firestore/cloud_firestore.dart';

class AccessLogModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String type; // 'check_in' | 'check_out'
  final DateTime timestamp;
  final String gateId;
  final String gateName;
  final String scannedBy;
  final String? scannedByName;
  final double? temperature;
  final String? note;
  final DateTime createdAt;

  AccessLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.timestamp,
    required this.gateId,
    required this.gateName,
    required this.scannedBy,
    this.scannedByName,
    this.temperature,
    this.note,
    required this.createdAt,
  });

  factory AccessLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccessLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      type: data['type'] ?? 'check_in',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gateId: data['gateId'] ?? '',
      gateName: data['gateName'] ?? '',
      scannedBy: data['scannedBy'] ?? '',
      scannedByName: data['scannedByName'],
      temperature: (data['temperature'] as num?)?.toDouble(),
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'gateId': gateId,
      'gateName': gateName,
      'scannedBy': scannedBy,
      'scannedByName': scannedByName,
      'temperature': temperature,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AccessLogModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? type,
    DateTime? timestamp,
    String? gateId,
    String? gateName,
    String? scannedBy,
    String? scannedByName,
    double? temperature,
    String? note,
    DateTime? createdAt,
  }) {
    return AccessLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      gateId: gateId ?? this.gateId,
      gateName: gateName ?? this.gateName,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedByName: scannedByName ?? this.scannedByName,
      temperature: temperature ?? this.temperature,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Getters
  bool get isCheckIn => type == 'check_in';
  bool get isCheckOut => type == 'check_out';

  String get typeDisplay => isCheckIn ? 'Vào' : 'Ra';

  String get timeDisplay {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get dateDisplay {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day/$month/$year';
  }
}
