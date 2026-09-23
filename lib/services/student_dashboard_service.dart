import '../core/network/api_client.dart';

class StudentDashboardService {
  StudentDashboardService._();

  // GET /api/student/dashboard (student resolved from JWT, no path variable)
  static Future<Map<String, dynamic>> getDashboard() {
    return ApiClient.get('/api/student/dashboard');
  }
}