import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String role; // 'employee','khách/nhà thầu' ,'guard', 'admin'

  // New fields for person-based access
  final String? employeeId; // Mã nhân viên
  final String userType; // 'employee' | 'contractor'
  final String? department; // Phòng ban (cho employee)
  final String? company; // Công ty (cho contractor)
  final String? photoUrl; // Ảnh đại diện
  final DateTime? validFrom; // Thời gian bắt đầu có hiệu lực
  final DateTime? validTo; // Thời gian hết hiệu lực

  final String status; // 'active', 'inactive', 'suspended'
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastLogin;

  // Legacy fields for backward compatibility
  final String? companyId;
  final String? companyName;

  UserModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.employeeId,
    this.userType = 'employee',
    this.department,
    this.company,
    this.photoUrl,
    this.validFrom,
    this.validTo,
    required this.status,
    this.fcmToken,
    required this.createdAt,
    this.lastLogin,
    this.companyId,
    this.companyName,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'employee',
      employeeId: data['employeeId'],
      userType: data['userType'] ?? 'employee',
      department: data['department'],
      company: data['company'],
      photoUrl: data['photoUrl'],
      validFrom: (data['validFrom'] as Timestamp?)?.toDate(),
      validTo: (data['validTo'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      companyId: data['companyId'],
      companyName: data['companyName'] ?? data['company'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'employeeId': employeeId,
      'userType': userType,
      'department': department,
      'company': company,
      'photoUrl': photoUrl,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
      'status': status,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'companyId': companyId,
      'companyName': companyName,
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? employeeId,
    String? userType,
    String? department,
    String? company,
    String? photoUrl,
    DateTime? validFrom,
    DateTime? validTo,
    String? status,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? companyId,
    String? companyName,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      userType: userType ?? this.userType,
      department: department ?? this.department,
      company: company ?? this.company,
      photoUrl: photoUrl ?? this.photoUrl,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
    );
  }

  // Role getters
  bool get isEmployee => role == 'employee';
  bool get isGuard => role == 'guard';
  bool get isAdmin => role == 'admin';

  // Type getters
  bool get isEmployeeType => userType == 'employee';
  bool get isContractor => userType == 'contractor';

  // Status getters
  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get isSuspended => status == 'suspended';

  // Validity check
  bool get isValidPeriod {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return true;
  }

  // Can access gate check
  bool get canAccessGate => isActive && isValidPeriod;

  // Display helpers
  String get displayId => employeeId ?? uid.substring(0, 6).toUpperCase();
  String get displayDepartmentOrCompany => department ?? company ?? 'N/A';
  String get userTypeDisplay => isContractor ? 'Nhà thầu' : 'Nhân viên';

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'suspended':
        return 'Tạm khóa';
      default:
        return status;
    }
  }
}
