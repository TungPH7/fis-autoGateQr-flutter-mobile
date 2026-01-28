import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/registration_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/check_in_provider.dart';
import 'providers/qr_provider.dart';
import 'providers/access_provider.dart';
import 'providers/gate_access_provider.dart';
import 'providers/gate_access_check_in_provider.dart';

// Customer App Screens (legacy - for vehicle registration)
import 'customer_app/screens/auth/login_screen.dart';
import 'customer_app/screens/auth/register_screen.dart';
import 'customer_app/screens/home/home_screen.dart';
import 'customer_app/screens/registration/create_registration_screen.dart';
import 'customer_app/screens/registration/registration_detail_screen.dart';
import 'customer_app/screens/registration/qr_display_screen.dart';
import 'customer_app/screens/vehicle/add_vehicle_screen.dart';
import 'customer_app/screens/vehicle/vehicle_detail_screen.dart';

// Employee App Screens (new - for person-based access)
import 'employee_app/screens/home/employee_home_screen.dart';
import 'employee_app/screens/gate_access/create_gate_access_screen.dart';
import 'employee_app/screens/gate_access/gate_access_list_screen.dart';
import 'employee_app/screens/history/employee_access_history_screen.dart';
import 'employee_app/screens/notifications/employee_notifications_screen.dart';
import 'employee_app/screens/profile/employee_profile_screen.dart';

// Guard App Screens
import 'guard_app/screens/auth/guard_login_screen.dart';
import 'guard_app/screens/auth/guard_register_screen.dart';
import 'guard_app/screens/home/guard_home_screen.dart';

// Models
import 'models/registration_model.dart';
import 'models/vehicle_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => QRProvider()),
        ChangeNotifierProvider(create: (_) => AccessProvider()),
        ChangeNotifierProvider(create: (_) => GateAccessProvider()),
        ChangeNotifierProvider(create: (_) => GateAccessCheckInProvider()),
      ],
      child: const AppSelector(),
    );
  }
}

// App Selector - Choose between Employee App and Guard App
class AppSelector extends StatelessWidget {
  const AppSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoGate QR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.customerTheme,
      home: const AppSelectorScreen(),
      routes: _buildRoutes(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Auth Routes (shared)
      '/login': (context) => const CustomerLoginScreen(),
      '/register': (context) => const CustomerRegisterScreen(),

      // Employee App Routes (new person-based system)
      '/employee/home': (context) => const EmployeeHomeScreen(),
      '/employee/gate-access': (context) => const GateAccessListScreen(),
      '/employee/gate-access/create': (context) => const CreateGateAccessScreen(),
      '/employee/history': (context) => const EmployeeAccessHistoryScreen(),
      '/employee/notifications': (context) => const EmployeeNotificationsScreen(),
      '/employee/profile': (context) => const EmployeeProfileScreen(),

      // Customer App Routes (legacy vehicle-based system)
      '/customer/home': (context) => const CustomerHomeScreen(),
      '/customer/registrations/create': (context) => const CreateRegistrationScreen(),
      '/customer/vehicles/add': (context) => const AddVehicleScreen(),

      // Guard App Routes
      '/guard/login': (context) => const GuardLoginScreen(),
      '/guard/register': (context) => const GuardRegisterScreen(),
      '/guard/home': (context) => const GuardHomeScreen(),
    };
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/customer/registrations/detail':
        final registration = settings.arguments as RegistrationModel;
        return MaterialPageRoute(
          builder: (context) => RegistrationDetailScreen(registration: registration),
        );
      case '/customer/qr-display':
        final registration = settings.arguments as RegistrationModel;
        return MaterialPageRoute(
          builder: (context) => QRDisplayScreen(registration: registration),
        );
      case '/customer/vehicles/detail':
        final vehicle = settings.arguments as VehicleModel;
        return MaterialPageRoute(
          builder: (context) => VehicleDetailScreen(vehicle: vehicle),
        );
      case '/customer/vehicles/edit':
        final vehicle = settings.arguments as VehicleModel;
        return MaterialPageRoute(
          builder: (context) => VehicleDetailScreen(vehicle: vehicle, isEditMode: true),
        );
      default:
        return null;
    }
  }
}

// Initial screen to select app type
class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if already logged in
        if (authProvider.state == AuthState.loading ||
            authProvider.state == AuthState.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          final user = authProvider.user;
          if (user != null) {
            if (user.isGuard) {
              return const GuardHomeScreen();
            } else {
              // Use new employee home screen for person-based access
              return const EmployeeHomeScreen();
            }
          }
        }

        // Show app selector
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gate QR',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn vai trò',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Employee App Button (Person-based access)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Khách/Nhà thầu và Nhân viên',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Đăng ký vào/ra cổng, hiển thị mã QR cá nhân',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guard App Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/guard/login');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: Colors.green,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bảo vệ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Quét QR & Check-in/out',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
