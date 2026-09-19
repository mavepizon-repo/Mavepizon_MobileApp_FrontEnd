import '../core/network/api_client.dart';

class AdminPermissionService {
  AdminPermissionService._();

  static Future<Map<String, dynamic>> getPending() {
    return ApiClient.get('/api/admin/teamlead/permissions/pending');
  }

  static Future<Map<String, dynamic>> approve(String permissionId) {
    return ApiClient.put(
        '/api/admin/teamlead/permissions/approve/$permissionId', {});
  }

  static Future<Map<String, dynamic>> reject(
      String permissionId, String remarks) {
    return ApiClient.put(
        '/api/admin/teamlead/permissions/reject/$permissionId'
        '?remarks=${Uri.encodeQueryComponent(remarks)}',
        {});
  }
}
