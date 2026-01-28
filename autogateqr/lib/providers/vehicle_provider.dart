import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';

class VehicleProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> get vehicles => _vehicles;
  List<VehicleModel> get activeVehicles =>
      _vehicles.where((v) => v.isActive).toList();
  VehicleModel? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load vehicles for owner
  void loadVehicles(String ownerId) {
    _firestoreService.getVehiclesByOwner(ownerId).listen(
      (vehicles) {
        _vehicles = vehicles;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Không thể tải danh sách xe';
        notifyListeners();
      },
    );
  }

  // Get vehicle by ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final vehicle = await _firestoreService.getVehicleById(vehicleId);
      _selectedVehicle = vehicle;
      _isLoading = false;
      notifyListeners();

      return vehicle;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải thông tin xe';
      notifyListeners();
      return null;
    }
  }

  // Add vehicle
  Future<String?> addVehicle({
    required String plateNumber,
    required String vehicleType,
    required String driverName,
    required String driverPhone,
    required String ownerId,
    String? brand,
    String? model,
    String? color,
    String? driverLicense,
    String? driverIdCard,
    String? companyId,
    String? companyName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final vehicle = VehicleModel(
        id: '',
        plateNumber: plateNumber,
        plateNumberNormalized: Helpers.normalizePlateNumber(plateNumber),
        vehicleType: vehicleType,
        brand: brand,
        model: model,
        color: color,
        driverName: driverName,
        driverPhone: driverPhone,
        driverLicense: driverLicense,
        driverIdCard: driverIdCard,
        companyId: companyId,
        companyName: companyName,
        ownerId: ownerId,
        status: AppConstants.vehicleActive,
        createdAt: DateTime.now(),
      );

      final id = await _firestoreService.addVehicle(vehicle);
      _isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể thêm xe: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Update vehicle
  Future<bool> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (data.containsKey('plateNumber')) {
        data['plateNumberNormalized'] = Helpers.normalizePlateNumber(data['plateNumber']);
      }

      await _firestoreService.updateVehicle(vehicleId, data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể cập nhật xe';
      notifyListeners();
      return false;
    }
  }

  // Delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteVehicle(vehicleId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể xóa xe';
      notifyListeners();
      return false;
    }
  }

  // Select vehicle
  void selectVehicle(VehicleModel? vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}