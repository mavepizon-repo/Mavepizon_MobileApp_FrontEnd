import '../core/network/api_client.dart';

class StudentNotificationService {
  StudentNotificationService._();

  // GET /api/student/notifications (student resolved from JWT, no path variable)
  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/student/notifications');
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    return ApiClient.patch(
        '/api/student/notifications/$notificationId/read', {});
  }
}
