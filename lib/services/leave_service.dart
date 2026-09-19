import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class LeaveService {
  LeaveService._();

  static Future<Map<String, dynamic>> getAllStaffLeaves() async {
    return ApiClient.get('/api/office-staff/leave');
  }

  static Future<Map<String, dynamic>> reviewStaffLeave(
      String leaveId, String status) async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.put(
        '/api/$teamLeadId/leave/$leaveId/review?status=$status', {});
  }

  static Future<Map<String, dynamic>> getMyLeaveHistory() async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/$teamLeadId/leave-history');
  }

  static Future<Map<String, dynamic>> applyTeamLeadLeave(
      Map<String, dynamic> data) async {
    final teamLeadId = await StorageHelper.getUserId();
    final body = {
      'startDate': data['startDate'] ?? '',
      'endDate': data['endDate'] ?? '',
      'reason': data['reason'] ?? '',
      'leaveType': data['leaveType'] ?? 'FULL_DAY',
    };
    return ApiClient.post('/api/$teamLeadId/leave-request', body);
  }
}