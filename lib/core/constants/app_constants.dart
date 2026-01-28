class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AutoGate QR';
  static const String appVersion = '2.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String accessLogsCollection = 'accessLogs';
  static const String gatesCollection = 'gates';
  static const String notificationsCollection = 'notifications';
  static const String contractorsCollection = 'contractors';

  // QR Code Settings
  static const int qrRefreshIntervalSeconds = 30;
  static const int qrValidityWindowSeconds = 60;
  static const String qrSecretKey = 'autogateqr_secret_2024'; // In production, use secure storage

  // Pagination
  static const int pageSize = 20;
  static const int accessHistoryDays = 7;

  // Date/Time Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // User Roles
  static const String roleEmployee = 'employee';
  static const String roleGuard = 'guard';
  static const String roleAdmin = 'admin';

  // User Types
  static const String userTypeEmployee = 'employee';
  static const String userTypeContractor = 'contractor';

  // User Status
  static const String userStatusActive = 'active';
  static const String userStatusInactive = 'inactive';
  static const String userStatusSuspended = 'suspended';

  // Access Log Types
  static const String accessTypeCheckIn = 'check_in';
  static const String accessTypeCheckOut = 'check_out';

  // Gate Type
  static const String gateTypeIn = 'in';
  static const String gateTypeOut = 'out';
  static const String gateTypeBoth = 'both';

  // Legacy: Firebase Collections (for vehicle-based system)
  static const String vehiclesCollection = 'vehicles';
  static const String registrationsCollection = 'registrations';
  static const String checkInOutsCollection = 'checkInOuts';

  // Legacy: Registration Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';
  static const String statusExpired = 'expired';

  // Legacy: Registration Types
  static const String regTypeEntry = 'entry';
  static const String regTypeExit = 'exit';
  static const String regTypeBoth = 'both';

  // Legacy: Check Status
  static const String checkStatusInProgress = 'in_progress';
  static const String checkStatusCompleted = 'completed';

  // Legacy: User Roles
  static const String roleCustomer = 'customer';

  // Legacy: Settings
  static const int maxAdvanceRegistrationDays = 30;

  // Legacy: Vehicle Status
  static const String vehicleActive = 'active';
  static const String vehicleInactive = 'inactive';
}
