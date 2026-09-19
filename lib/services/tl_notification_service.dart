import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class TlNotificationService {
  TlNotificationService._();

  static Future<Map<String, dynamic>> getAll() async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/teamlead/$teamLeadId/notifications');
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    return ApiClient.patch(
        '/api/teamlead/notifications/$notificationId/read', {});
  }
}
