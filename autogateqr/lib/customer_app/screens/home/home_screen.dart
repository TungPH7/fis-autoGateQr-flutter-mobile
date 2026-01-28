import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/registration_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../registration/registration_list_screen.dart';
import '../vehicle/vehicle_list_screen.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  bool _dataLoaded = false;
  AuthProvider? _authProvider;
  bool _isListenerAdded = false;

  final List<Widget> _screens = [
    const RegistrationListScreen(),
    const VehicleListScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (_dataLoaded || !mounted) return;

    _authProvider = context.read<AuthProvider>();
    if (_authProvider?.user != null) {
      _dataLoaded = true;
      context.read<RegistrationProvider>().loadRegistrations(_authProvider!.user!.uid);
      context.read<VehicleProvider>().loadVehicles(_authProvider!.user!.uid);
    } else {
      // Listen for auth state changes
      _isListenerAdded = true;
      _authProvider?.addListener(_onAuthChanged);
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (!_dataLoaded && _authProvider?.user != null) {
      _dataLoaded = true;
      context.read<RegistrationProvider>().loadRegistrations(_authProvider!.user!.uid);
      context.read<VehicleProvider>().loadVehicles(_authProvider!.user!.uid);
      _authProvider?.removeListener(_onAuthChanged);
      _isListenerAdded = false;
    }
  }

  @override
  void dispose() {
    if (_isListenerAdded && _authProvider != null) {
      _authProvider!.removeListener(_onAuthChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Đăng ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Xe',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/customer/registrations/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đăng ký'),
            )
          : _currentIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/customer/vehicles/add');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm xe'),
                )
              : null,
    );
  }
}
