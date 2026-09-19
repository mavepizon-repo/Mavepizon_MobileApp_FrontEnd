import '../core/network/api_client.dart';

class AdminLeaveService {
  AdminLeaveService._();

  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/admin/teamlead-leaves');
  }

  static Future<Map<String, dynamic>> reviewLeave(
      String adminId, String leaveId, String status) {
    return ApiClient.put(
        '/api/admin/$adminId/teamlead-leave/$leaveId/review?status=$status',
        {});
  }
}
