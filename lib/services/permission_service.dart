import '../core/network/api_client.dart';

class PermissionService {
  PermissionService._();

  static Future<Map<String, dynamic>> getBranchPermissions() {
    return ApiClient.get('/api/officeStaff/permissions/byBranch');
  }

  static Future<Map<String, dynamic>> getPendingPermissions() {
    return ApiClient.get('/api/teamlead/officeStaff/permissions/pending');
  }

  static Future<Map<String, dynamic>> approvePermission(
      String permissionId) async {
    return ApiClient.put(
        '/api/teamlead/officestaff/permissions/approve/$permissionId', {});
  }

  static Future<Map<String, dynamic>> rejectPermission(
      String permissionId, String remarks) async {
    return ApiClient.put(
        '/api/teamlead/officestaff/permissions/reject/$permissionId'
        '?remarks=${Uri.encodeQueryComponent(remarks)}',
        {});
  }

  static Future<Map<String, dynamic>> getMyPermissionHistory() {
    return ApiClient.get('/api/teamlead/permissions/history');
  }

  static Future<Map<String, dynamic>> applyTeamLeadPermission(
      Map<String, dynamic> data) async {
    final body = {
      'permissionDate': data['permissionDate'] ?? '',
      'durationHours': data['durationHours'] ?? 1,
      'reason': data['reason'] ?? '',
    };
    return ApiClient.post('/api/teamlead/permission-request', body);
  }
}
