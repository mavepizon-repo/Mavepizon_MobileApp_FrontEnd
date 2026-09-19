import '../core/network/api_client.dart';

class StaffLeaveService {
  StaffLeaveService._();

  static Future<Map<String, dynamic>> applyLeave(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.post('/api/officestaff/$staffId/leave', data);
  }

  static Future<Map<String, dynamic>> getLeaveHistory(String staffId) {
    return ApiClient.get('/api/officestaff/$staffId/leave-history');
  }
}
