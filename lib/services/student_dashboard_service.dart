import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StudentDashboardService {
  StudentDashboardService._();

  static Future<Map<String, dynamic>> getDashboard() async {
    final studentId = await StorageHelper.getUserId();
    return ApiClient.get('/api/student/$studentId/dashboard');
  }
}
