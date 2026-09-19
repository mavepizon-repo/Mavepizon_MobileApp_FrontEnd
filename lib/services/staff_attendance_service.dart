import '../core/network/api_client.dart';

class StaffAttendanceService {
  StaffAttendanceService._();

  static Future<Map<String, dynamic>> checkIn(
      double latitude, double longitude) {
    return ApiClient.post(
        '/api/officestaff/checkin',
        {'latitude': latitude, 'longitude': longitude});
  }

  static Future<Map<String, dynamic>> checkOut() {
    return ApiClient.post('/api/officestaff/checkout', {});
  }

  static Future<Map<String, dynamic>> getHistory() {
    return ApiClient.get('/api/officestaff/attendance-history');
  }
}
