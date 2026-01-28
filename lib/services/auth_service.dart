import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update last login (use set with merge to create doc if not exists)
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set({
              'lastLogin': FieldValue.serverTimestamp(),
              'email': credential.user!.email,
            }, SetOptions(merge: true));

        return await getUserProfile(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? employeeId,
    String userType = 'employee',
    String? department,
    String? company,
    String? photoUrl,
    DateTime? validFrom,
    DateTime? validTo,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
          phone: phone,
          role: role,
          employeeId: employeeId,
          userType: userType,
          department: department,
          company: company,
          photoUrl: photoUrl,
          validFrom: validFrom ?? DateTime.now(),
          validTo: validTo,
          status: AppConstants.userStatusActive,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Create user profile (for admin creating users)
  Future<UserModel?> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String role,
    String? employeeId,
    String userType = 'employee',
    String? department,
    String? company,
    String? photoUrl,
    DateTime? validFrom,
    DateTime? validTo,
  }) async {
    try {
      final user = UserModel(
        id: uid,
        uid: uid,
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        employeeId: employeeId,
        userType: userType,
        department: department,
        company: company,
        photoUrl: photoUrl,
        validFrom: validFrom ?? DateTime.now(),
        validTo: validTo,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  // Update FCM token
  Future<void> updateFCMToken(String uid, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Không tìm thấy người dùng');
    }

    // Re-authenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
  }

  // Get auth error message
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác';
      default:
        return e.message ?? 'Đã xảy ra lỗi';
    }
  }
}