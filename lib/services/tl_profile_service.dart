import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class TlProfileService {
  TlProfileService._();

  // GET /api/{teamLeadId}/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/$teamLeadId/profile');
  }

  // GET /api/{teamLeadId}/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/$teamLeadId/dashboard');
  }
}