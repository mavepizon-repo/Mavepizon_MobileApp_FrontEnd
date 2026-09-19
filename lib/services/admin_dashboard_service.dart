import '../core/network/api_client.dart';

class AdminDashboardService {
  AdminDashboardService._();

  static Future<Map<String, dynamic>> getStats() {
    return ApiClient.get('/api/admin/dashboard');
  }
}
