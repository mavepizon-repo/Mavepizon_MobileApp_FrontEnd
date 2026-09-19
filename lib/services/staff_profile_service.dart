import '../core/network/api_client.dart';

class StaffProfileService {
  StaffProfileService._();

  static Future<Map<String, dynamic>> getProfile(String staffId) {
    return ApiClient.get('/api/officestaff/$staffId/profile');
  }

  static Future<Map<String, dynamic>> getPerformanceSummary(String staffId) {
    return ApiClient.get('/api/officestaff/$staffId/performance-summary');
  }

  static Future<Map<String, dynamic>> getLeaderboard() {
    return ApiClient.get('/api/officestaff/leaderboard');
  }
}
