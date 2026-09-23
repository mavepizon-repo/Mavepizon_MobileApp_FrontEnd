import '../core/network/api_client.dart';

class AdminLeaveService {
  AdminLeaveService._();

  static Future<Map<String, dynamic>> getAll(
      {int page = 0, int size = 20}) {
    return ApiClient.get(
      '/api/admin/teamlead-leaves',
      queryParams: {'page': '$page', 'size': '$size'},
    );
  }

  static Future<Map<String, dynamic>> reviewLeave(
      String adminId, String leaveId, String status) {
    return ApiClient.put(
        '/api/admin/$adminId/teamlead-leave/$leaveId/review?status=$status',
        {});
  }
}
