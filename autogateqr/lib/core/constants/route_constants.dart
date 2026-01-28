class RouteConstants {
  RouteConstants._();

  // Common Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Customer App Routes
  static const String customerHome = '/customer/home';
  static const String customerDashboard = '/customer/dashboard';
  static const String registrationList = '/customer/registrations';
  static const String createRegistration = '/customer/registrations/create';
  static const String registrationDetail = '/customer/registrations/detail';
  static const String qrDisplay = '/customer/qr-display';
  static const String vehicleList = '/customer/vehicles';
  static const String addVehicle = '/customer/vehicles/add';
  static const String vehicleDetail = '/customer/vehicles/detail';
  static const String history = '/customer/history';
  static const String historyDetail = '/customer/history/detail';
  static const String notifications = '/customer/notifications';
  static const String profile = '/customer/profile';
  static const String settings = '/customer/settings';

  // Guard App Routes
  static const String guardHome = '/guard/home';
  static const String guardDashboard = '/guard/dashboard';
  static const String qrScanner = '/guard/scanner';
  static const String scanResult = '/guard/scanner/result';
  static const String checkIn = '/guard/check-in';
  static const String checkOut = '/guard/check-out';
  static const String activeVehicles = '/guard/active-vehicles';
  static const String incidentReport = '/guard/incident-report';
  static const String dailyReport = '/guard/daily-report';
  static const String guardProfile = '/guard/profile';
}