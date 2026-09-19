import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StudentNotificationService {
  StudentNotificationService._();

  static Future<Map<String, dynamic>> getAll() async {
    final studentId = await StorageHelper.getUserId();
    return ApiClient.get('/api/student/$studentId/notifications');
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    return ApiClient.patch(
        '/api/student/notifications/$notificationId/read', {});
  }
}
