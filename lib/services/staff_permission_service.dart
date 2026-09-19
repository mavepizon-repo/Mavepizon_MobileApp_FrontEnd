import '../core/network/api_client.dart';

class StaffPermissionService {
  StaffPermissionService._();

  static Future<Map<String, dynamic>> applyPermission(
      Map<String, dynamic> data) {
    return ApiClient.post('/api/officestaff/permissions-request', data);
  }

  static Future<Map<String, dynamic>> getPermissionHistory() {
    return ApiClient.get('/api/officestaff/permissions/history');
  }
}
