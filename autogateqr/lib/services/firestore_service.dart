import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import '../models/registration_model.dart';
import '../models/check_in_out_model.dart';
import '../models/gate_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/access_log_model.dart';
import '../models/gate_access_registration_model.dart';
import '../models/visitor_access_log_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Get user by UID (Firebase Auth UID)
  Future<UserModel?> getUserByUid(String uid) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Get user by employee ID
  Future<UserModel?> getUserByEmployeeId(String employeeId) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('employeeId', isEqualTo: employeeId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Stream user data for real-time updates
  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  // Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'status': status});
  }

  // ==================== ACCESS LOGS ====================

  // Create access log (check-in or check-out)
  Future<String> createAccessLog(AccessLogModel log) async {
    final docRef = await _firestore
        .collection(AppConstants.accessLogsCollection)
        .add(log.toFirestore());
    return docRef.id;
  }

  // Get access logs by user (recent history)
  Stream<List<AccessLogModel>> getAccessLogsByUser(String userId, {int days = 7}) {
    final startDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection(AppConstants.accessLogsCollection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get today's access logs by user
  Stream<List<AccessLogModel>> getTodayAccessLogs(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(AppConstants.accessLogsCollection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get last access log for a user (to determine current status)
  Future<AccessLogModel?> getLastAccessLog(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.accessLogsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AccessLogModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Get all access logs for a gate (today)
  Stream<List<AccessLogModel>> getGateAccessLogs(String gateId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection(AppConstants.accessLogsCollection)
        .where('gateId', isEqualTo: gateId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get current people inside (checked-in but not checked-out)
  Future<int> getCurrentPeopleCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Get today's logs
    final snapshot = await _firestore
        .collection(AppConstants.accessLogsCollection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: false)
        .get();

    // Count check-ins and check-outs per user
    final userStatus = <String, String>{};
    for (final doc in snapshot.docs) {
      final log = AccessLogModel.fromFirestore(doc);
      userStatus[log.userId] = log.type;
    }

    // Count users whose last action was check-in
    return userStatus.values.where((type) => type == AppConstants.accessTypeCheckIn).length;
  }

  // Check if user is currently inside
  Future<bool> isUserInside(String userId) async {
    final lastLog = await getLastAccessLog(userId);
    if (lastLog == null) return false;

    // Check if the last log was today and was a check-in
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(lastLog.timestamp.year, lastLog.timestamp.month, lastLog.timestamp.day);

    return logDate == today && lastLog.isCheckIn;
  }

  // ==================== VEHICLES ====================

  // Get vehicles by owner
  Stream<List<VehicleModel>> getVehiclesByOwner(String ownerId) {
    return _firestore
        .collection(AppConstants.vehiclesCollection)
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isNotEqualTo: 'deleted')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromFirestore(doc))
            .toList());
  }

  // Get vehicle by ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    final doc = await _firestore
        .collection(AppConstants.vehiclesCollection)
        .doc(vehicleId)
        .get();

    if (doc.exists) {
      return VehicleModel.fromFirestore(doc);
    }
    return null;
  }

  // Add vehicle
  Future<String> addVehicle(VehicleModel vehicle) async {
    final docRef = await _firestore
        .collection(AppConstants.vehiclesCollection)
        .add(vehicle.toFirestore());
    return docRef.id;
  }

  // Update vehicle
  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.vehiclesCollection)
        .doc(vehicleId)
        .update(data);
  }

  // Delete vehicle (soft delete)
  Future<void> deleteVehicle(String vehicleId) async {
    await updateVehicle(vehicleId, {'status': 'deleted'});
  }

  // ==================== REGISTRATIONS ====================

  // Get registrations by user
  Stream<List<RegistrationModel>> getRegistrationsByUser(String userId) {
    return _firestore
        .collection(AppConstants.registrationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get registrations by status
  Stream<List<RegistrationModel>> getRegistrationsByStatus(String userId, String status) {
    return _firestore
        .collection(AppConstants.registrationsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get registration by ID
  Future<RegistrationModel?> getRegistrationById(String registrationId) async {
    final doc = await _firestore
        .collection(AppConstants.registrationsCollection)
        .doc(registrationId)
        .get();

    if (doc.exists) {
      return RegistrationModel.fromFirestore(doc);
    }
    return null;
  }

  // Create registration
  Future<String> createRegistration(RegistrationModel registration) async {
    final docRef = await _firestore
        .collection(AppConstants.registrationsCollection)
        .add(registration.toFirestore());
    return docRef.id;
  }

  // Update registration
  Future<void> updateRegistration(String registrationId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.registrationsCollection)
        .doc(registrationId)
        .update(data);
  }

  // Approve registration with QR code
  Future<void> approveRegistration({
    required String registrationId,
    required String approvedBy,
    required String approvedByName,
    required String qrCode,
    required DateTime qrExpiresAt,
  }) async {
    await _firestore
        .collection(AppConstants.registrationsCollection)
        .doc(registrationId)
        .update({
      'status': AppConstants.statusApproved,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': FieldValue.serverTimestamp(),
      'qrCode': qrCode,
      'qrGeneratedAt': FieldValue.serverTimestamp(),
      'qrExpiresAt': Timestamp.fromDate(qrExpiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject registration
  Future<void> rejectRegistration({
    required String registrationId,
    required String rejectedBy,
    required String reason,
  }) async {
    await _firestore
        .collection(AppConstants.registrationsCollection)
        .doc(registrationId)
        .update({
      'status': AppConstants.statusRejected,
      'approvedBy': rejectedBy,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== CHECK-IN/OUT ====================

  // Get active check-ins (vehicles currently inside)
  Stream<List<CheckInOutModel>> getActiveCheckIns() {
    return _firestore
        .collection(AppConstants.checkInOutsCollection)
        .where('status', isEqualTo: AppConstants.checkStatusInProgress)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CheckInOutModel.fromFirestore(doc))
            .toList());
  }

  // Get check-ins by date
  Stream<List<CheckInOutModel>> getCheckInsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(AppConstants.checkInOutsCollection)
        .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkInTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CheckInOutModel.fromFirestore(doc))
            .toList());
  }

  // Get check-in/out by registration
  Future<CheckInOutModel?> getCheckInOutByRegistration(String registrationId) async {
    final snapshot = await _firestore
        .collection(AppConstants.checkInOutsCollection)
        .where('registrationId', isEqualTo: registrationId)
        .where('status', isEqualTo: AppConstants.checkStatusInProgress)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CheckInOutModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Create check-in
  Future<String> createCheckIn(CheckInOutModel checkIn) async {
    final docRef = await _firestore
        .collection(AppConstants.checkInOutsCollection)
        .add(checkIn.toFirestore());
    return docRef.id;
  }

  // Update check-out
  Future<void> updateCheckOut({
    required String checkInOutId,
    required DateTime checkOutTime,
    String? checkOutImage,
    GeoPoint? checkOutLocation,
    String? notes,
  }) async {
    final checkIn = await _firestore
        .collection(AppConstants.checkInOutsCollection)
        .doc(checkInOutId)
        .get();

    if (!checkIn.exists) return;

    final checkInData = CheckInOutModel.fromFirestore(checkIn);
    final duration = checkOutTime.difference(checkInData.checkInTime!).inMinutes;

    await _firestore
        .collection(AppConstants.checkInOutsCollection)
        .doc(checkInOutId)
        .update({
      'checkOutTime': Timestamp.fromDate(checkOutTime),
      'checkOutImage': checkOutImage,
      'checkOutLocation': checkOutLocation,
      'durationMinutes': duration,
      'notes': notes,
      'status': AppConstants.checkStatusCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update registration status to completed
    await updateRegistration(checkInData.registrationId, {
      'status': AppConstants.statusCompleted,
    });
  }

  // ==================== GATES ====================

  // Get all active gates
  Stream<List<GateModel>> getActiveGates() {
    return _firestore
        .collection(AppConstants.gatesCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateModel.fromFirestore(doc))
            .toList());
  }

  // Get gate by ID
  Future<GateModel?> getGateById(String gateId) async {
    final doc = await _firestore
        .collection(AppConstants.gatesCollection)
        .doc(gateId)
        .get();

    if (doc.exists) {
      return GateModel.fromFirestore(doc);
    }
    return null;
  }

  // ==================== NOTIFICATIONS ====================

  // Get notifications by user
  Stream<List<NotificationModel>> getNotificationsByUser(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Create notification
  Future<String> createNotification(NotificationModel notification) async {
    final docRef = await _firestore
        .collection(AppConstants.notificationsCollection)
        .add(notification.toFirestore());
    return docRef.id;
  }

  // ==================== HISTORY ====================

  // Get user history (completed check-ins)
  Stream<List<CheckInOutModel>> getUserHistory(String userId) {
    return _firestore
        .collection(AppConstants.checkInOutsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.checkStatusCompleted)
        .orderBy('checkOutTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CheckInOutModel.fromFirestore(doc))
            .toList());
  }

  // ==================== GATE ACCESS REGISTRATIONS ====================

  static const String gateAccessRegistrationsCollection = 'gateAccessRegistrations';

  // Create gate access registration
  Future<String> createGateAccessRegistration(GateAccessRegistrationModel registration) async {
    final docRef = await _firestore
        .collection(gateAccessRegistrationsCollection)
        .add(registration.toFirestore());
    return docRef.id;
  }

  // Get gate access registrations by user
  Stream<List<GateAccessRegistrationModel>> getGateAccessRegistrationsByUser(String userId) {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get gate access registrations by user and status
  Stream<List<GateAccessRegistrationModel>> getGateAccessRegistrationsByStatus(
      String userId, String status) {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get approved registrations for today (for QR display)
  Stream<List<GateAccessRegistrationModel>> getApprovedRegistrationsForToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.statusApproved)
        .where('expectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('expectedDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get gate access registration by ID
  Future<GateAccessRegistrationModel?> getGateAccessRegistrationById(String registrationId) async {
    final doc = await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .get();

    if (doc.exists) {
      return GateAccessRegistrationModel.fromFirestore(doc);
    }
    return null;
  }

  // Get gate access registration by QR code
  Future<GateAccessRegistrationModel?> getGateAccessRegistrationByQRCode(String qrCode) async {
    final snapshot = await _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return GateAccessRegistrationModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Update gate access registration
  Future<void> updateGateAccessRegistration(
      String registrationId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update(data);
  }

  // Get all gate access registrations (for guards/admins)
  Stream<List<GateAccessRegistrationModel>> getAllGateAccessRegistrations() {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get today's gate access registrations (for guards)
  Stream<List<GateAccessRegistrationModel>> getTodayGateAccessRegistrations() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('expectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('expectedDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('expectedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get gate access registrations by status (for guards/admins)
  Stream<List<GateAccessRegistrationModel>> getGateAccessRegistrationsByStatusForGuard(
      String status) {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Cancel gate access registration (user cancels their own request)
  Future<void> cancelGateAccessRegistration(String registrationId) async {
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Approve gate access registration (Admin)
  Future<void> approveGateAccessRegistration({
    required String registrationId,
    required String approvedBy,
    required String approvedByName,
    required String qrCode,
    required DateTime qrExpiresAt,
  }) async {
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'status': AppConstants.statusApproved,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': FieldValue.serverTimestamp(),
      'qrCode': qrCode,
      'qrExpiresAt': Timestamp.fromDate(qrExpiresAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject gate access registration (Admin)
  Future<void> rejectGateAccessRegistration({
    required String registrationId,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'status': AppConstants.statusRejected,
      'approvedBy': rejectedBy,
      'approvedByName': rejectedByName,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark registration as used (after check-in)
  Future<void> markGateAccessRegistrationAsUsed(String registrationId) async {
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'status': 'used',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all pending registrations (for Admin)
  Stream<List<GateAccessRegistrationModel>> getPendingGateAccessRegistrations() {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get all registrations for a date (for Admin)
  Stream<List<GateAccessRegistrationModel>> getGateAccessRegistrationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('expectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('expectedDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('expectedDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // ==================== VISITOR ACCESS LOGS ====================

  static const String visitorAccessLogsCollection = 'visitorAccessLogs';

  // Check-in visitor (Guard confirms visitor entry)
  Future<void> checkInVisitor({
    required String registrationId,
    required String guardId,
    String? guardName,
    String? gateId,
    String? gateName,
  }) async {
    // Get registration data first
    final registration = await getGateAccessRegistrationById(registrationId);
    if (registration == null) {
      throw Exception('Registration not found');
    }

    final now = DateTime.now();

    // Update registration
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'actualCheckInTime': Timestamp.fromDate(now),
      'checkInGuardId': guardId,
      'checkInGateId': gateId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create access log
    final log = VisitorAccessLogModel(
      id: '',
      registrationId: registrationId,
      visitorName: registration.fullName,
      visitorPhone: registration.phone,
      visitorIdCard: registration.idCard,
      visitorType: registration.visitorType,
      type: 'check_in',
      timestamp: now,
      gateId: gateId,
      gateName: gateName,
      guardId: guardId,
      guardName: guardName,
      purpose: registration.purpose,
      addressOrCompany: registration.addressOrCompany ?? registration.companyName ?? registration.address,
      idCardHeldByGuard: registration.idCardHeldByGuard,
      accessCardNumber: registration.accessCardNumber,
      vehiclePlate: registration.vehiclePlate,
      vehicleType: registration.vehicleType,
      createdAt: now,
    );

    await _firestore
        .collection(visitorAccessLogsCollection)
        .add(log.toFirestore());
  }

  // Check-out visitor (Guard confirms visitor exit)
  Future<void> checkOutVisitor({
    required String registrationId,
    required String guardId,
    String? guardName,
    String? gateId,
    String? gateName,
    bool accessCardReturned = false,
    bool idCardReturned = false,
  }) async {
    // Get registration data first
    final registration = await getGateAccessRegistrationById(registrationId);
    if (registration == null) {
      throw Exception('Registration not found');
    }

    final now = DateTime.now();

    // Update registration
    await _firestore
        .collection(gateAccessRegistrationsCollection)
        .doc(registrationId)
        .update({
      'actualCheckOutTime': Timestamp.fromDate(now),
      'checkOutGuardId': guardId,
      'checkOutGateId': gateId,
      'status': 'used',
      'accessCardReturned': accessCardReturned,
      'idCardReturned': idCardReturned,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create access log
    final log = VisitorAccessLogModel(
      id: '',
      registrationId: registrationId,
      visitorName: registration.fullName,
      visitorPhone: registration.phone,
      visitorIdCard: registration.idCard,
      visitorType: registration.visitorType,
      type: 'check_out',
      timestamp: now,
      gateId: gateId,
      gateName: gateName,
      guardId: guardId,
      guardName: guardName,
      purpose: registration.purpose,
      addressOrCompany: registration.addressOrCompany ?? registration.companyName ?? registration.address,
      idCardHeldByGuard: registration.idCardHeldByGuard,
      accessCardNumber: registration.accessCardNumber,
      vehiclePlate: registration.vehiclePlate,
      vehicleType: registration.vehicleType,
      createdAt: now,
    );

    await _firestore
        .collection(visitorAccessLogsCollection)
        .add(log.toFirestore());
  }

  // Get all visitor access logs
  Stream<List<VisitorAccessLogModel>> getAllVisitorAccessLogs() {
    return _firestore
        .collection(visitorAccessLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get recent visitor access logs with limit
  Stream<List<VisitorAccessLogModel>> getRecentVisitorAccessLogs(int limit) {
    return _firestore
        .collection(visitorAccessLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get visitor access logs for last N days
  Stream<List<VisitorAccessLogModel>> getVisitorAccessLogsLastDays(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    return _firestore
        .collection(visitorAccessLogsCollection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get today's visitor access logs
  Stream<List<VisitorAccessLogModel>> getTodayVisitorAccessLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(visitorAccessLogsCollection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get visitor access logs by type (check_in or check_out)
  Stream<List<VisitorAccessLogModel>> getVisitorAccessLogsByType(String type) {
    return _firestore
        .collection(visitorAccessLogsCollection)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get today's registrations by createdAt (for Guard - đăng ký hôm nay)
  Stream<List<GateAccessRegistrationModel>> getTodayCreatedRegistrations() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get visitors currently inside (checked in but not checked out)
  Stream<List<GateAccessRegistrationModel>> getVisitorsCurrentlyInside() {
    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('actualCheckInTime', isNull: false)
        .where('actualCheckOutTime', isNull: true)
        .orderBy('actualCheckInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Get registrations from last N days (for Guard)
  Stream<List<GateAccessRegistrationModel>> getRegistrationsLastDays(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    return _firestore
        .collection(gateAccessRegistrationsCollection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GateAccessRegistrationModel.fromFirestore(doc))
            .toList());
  }

  // Create visitor access log
  Future<String> createVisitorAccessLog(VisitorAccessLogModel log) async {
    final docRef = await _firestore
        .collection(visitorAccessLogsCollection)
        .add(log.toFirestore());
    return docRef.id;
  }

  // Delete visitor access log
  Future<void> deleteVisitorAccessLog(String logId) async {
    await _firestore.collection(visitorAccessLogsCollection).doc(logId).delete();
  }

  // Get visitor access logs by phone number (for employee/contractor app)
  Stream<List<VisitorAccessLogModel>> getVisitorAccessLogsByPhone(String phone, {int days = 7}) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    return _firestore
        .collection(visitorAccessLogsCollection)
        .where('visitorPhone', isEqualTo: phone)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
            .toList());
  }

  // Get last visitor access log by phone (to check current status)
  Future<VisitorAccessLogModel?> getLastVisitorAccessLogByPhone(String phone) async {
    final snapshot = await _firestore
        .collection(visitorAccessLogsCollection)
        .where('visitorPhone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return VisitorAccessLogModel.fromFirestore(snapshot.docs.first);
  }

  // Check if user is inside by phone number
  Future<bool> isUserInsideByPhone(String phone) async {
    final lastLog = await getLastVisitorAccessLogByPhone(phone);
    if (lastLog == null) return false;

    // Check if last log was today and is check-in
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(
      lastLog.timestamp.year,
      lastLog.timestamp.month,
      lastLog.timestamp.day,
    );

    return logDate == today && lastLog.isCheckIn;
  }

  // Get visitor access logs by phone number AND visitor type (for employee/contractor/visitor app)
  // visitorType: 'employee', 'contractor', 'visitor' - if null, returns all logs for that phone
  // Note: visitorType is filtered client-side to avoid requiring composite index
  Stream<List<VisitorAccessLogModel>> getVisitorAccessLogsByPhoneAndType(
    String phone, {
    String? visitorType,
    int days = 7,
  }) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    // Query only by phone and timestamp (uses existing index)
    return _firestore
        .collection(visitorAccessLogsCollection)
        .where('visitorPhone', isEqualTo: phone)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          List<VisitorAccessLogModel> logs = snapshot.docs
              .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
              .toList();

          // Filter by visitorType on client side if provided
          if (visitorType != null && visitorType.isNotEmpty) {
            logs = logs.where((log) => log.visitorType == visitorType).toList();
          }

          return logs;
        });
  }

  // Get last visitor access log by phone AND visitor type
  // Note: visitorType is filtered client-side to avoid requiring composite index
  Future<VisitorAccessLogModel?> getLastVisitorAccessLogByPhoneAndType(
    String phone, {
    String? visitorType,
  }) async {
    // Query by phone only, get recent logs to filter client-side
    final snapshot = await _firestore
        .collection(visitorAccessLogsCollection)
        .where('visitorPhone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .limit(20) // Get more to filter, in case some don't match visitorType
        .get();

    if (snapshot.docs.isEmpty) return null;

    // Convert and filter by visitorType if provided
    final logs = snapshot.docs
        .map((doc) => VisitorAccessLogModel.fromFirestore(doc))
        .toList();

    if (visitorType != null && visitorType.isNotEmpty) {
      final filtered = logs.where((log) => log.visitorType == visitorType).toList();
      return filtered.isNotEmpty ? filtered.first : null;
    }

    return logs.first;
  }

  // Check if user is inside by phone number AND visitor type
  Future<bool> isUserInsideByPhoneAndType(
    String phone, {
    String? visitorType,
  }) async {
    final lastLog = await getLastVisitorAccessLogByPhoneAndType(
      phone,
      visitorType: visitorType,
    );
    if (lastLog == null) return false;

    // Check if last log was today and is check-in
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(
      lastLog.timestamp.year,
      lastLog.timestamp.month,
      lastLog.timestamp.day,
    );

    return logDate == today && lastLog.isCheckIn;
  }
}