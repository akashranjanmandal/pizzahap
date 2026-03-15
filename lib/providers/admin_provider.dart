import 'package:flutter/foundation.dart';
import '../services/admin_api_service.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  Map<String, dynamic>? _admin;
  bool _isAdminLoggedIn = false;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get admin           => _admin;
  bool   get isAdminLoggedIn                => _isAdminLoggedIn;
  bool   get loading                        => _loading;
  String? get error                         => _error;
  String get adminRole      => _admin?['role']          ?? 'staff';
  String get adminName      => _admin?['name']          ?? 'Admin';
  int?   get adminLocationId => _admin?['location_id']  as int?;
  String? get adminLocationName => _admin?['location_name'] as String?;
  bool   get canManage => adminRole == 'super_admin' || adminRole == 'admin';
  bool   get isSuperAdmin => adminRole == 'super_admin';

  Future<bool> login(String email, String password, {int? locationId}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final data = await AdminApiService.login(email, password, locationId: locationId);
      _admin = data['admin'] as Map<String, dynamic>;
      _isAdminLoggedIn = true;
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  void logout() {
    _admin = null;
    _isAdminLoggedIn = false;
    ApiService.clearTokens();
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
