import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String? taxCode;
  final String? address;
  final String? phone;
  final String? email;
  final String status;
  final bool isTrusted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.taxCode,
    this.address,
    this.phone,
    this.email,
    required this.status,
    this.isTrusted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      taxCode: data['taxCode'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      status: data['status'] ?? 'active',
      isTrusted: data['isTrusted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'taxCode': taxCode,
      'address': address,
      'phone': phone,
      'email': email,
      'status': status,
      'isTrusted': isTrusted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? taxCode,
    String? address,
    String? phone,
    String? email,
    String? status,
    bool? isTrusted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      taxCode: taxCode ?? this.taxCode,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      isTrusted: isTrusted ?? this.isTrusted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
