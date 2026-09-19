import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StaffTaskService {
  StaffTaskService._();

  // GET /api/officestaff/task/mytasks
  static Future<Map<String, dynamic>> getTasks(String staffId) {
    return ApiClient.get('/api/officestaff/task/mytasks');
  }

  // PUT /api/officestaff/task/progress/{taskId}
  // On a 500, reconcile by refetching instead of reporting a failure.
  static Future<Map<String, dynamic>> updateProgress(
      String taskId, Map<String, dynamic> data) async {
    final result =
        await ApiClient.put('/api/officestaff/task/progress/$taskId', data);
    if (result['success'] == true || result['status'] != 500) return result;

    final detail = await getTaskDetail(taskId);
    if (detail['success'] == true && detail['data'] is Map) {
      final d = detail['data'] as Map;
      final progressMatches = (d['progress'] ?? 0).toString() ==
          (data['progressPercentage'] ?? 0).toString();
      final statusMatches = (d['status'] ?? '').toString().toUpperCase() ==
          (data['status'] ?? '').toString().toUpperCase();
      if (progressMatches && statusMatches) {
        return {'success': true, 'data': d, 'reconciled': true};
      }
    }
    return result;
  }

  // PUT /api/officestaff/task/submit/{taskId}
  // On a 500, reconcile by refetching the saved status.
  static Future<Map<String, dynamic>> submitTask(String taskId) async {
    final result =
        await ApiClient.put('/api/officestaff/task/submit/$taskId', {});
    if (result['success'] == true || result['status'] != 500) return result;

    final detail = await getTaskDetail(taskId);
    if (detail['success'] == true && detail['data'] is Map) {
      final d = detail['data'] as Map;
      if ((d['status'] ?? '').toString().toUpperCase() ==
          'WAITING_FOR_REVIEW') {
        return {'success': true, 'data': d, 'reconciled': true};
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
    final staffId = await StorageHelper.getStaffId();
    if (staffId == null || staffId.isEmpty) {
      return {'success': false, 'message': 'Staff ID not found'};
    }
    final result = await ApiClient.get('/api/officestaff/task/mytasks');
    if (result['success'] == true && result['data'] is List) {
      final tasks = result['data'] as List;
      final task = tasks.cast<Map<String, dynamic>>().firstWhere(
        (t) => t['taskId']?.toString() == taskId || t['id']?.toString() == taskId,
        orElse: () => <String, dynamic>{},
      );
      if (task.isNotEmpty) {
        return {'success': true, 'data': task};
      }
      return {'success': false, 'message': 'Task not found'};
    }
    return result;
  }
}
