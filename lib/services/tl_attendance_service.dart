import '../core/network/api_client.dart';

class TlAttendanceService {
  TlAttendanceService._();

  static Future<Map<String, dynamic>> checkIn(
      double latitude, double longitude) {
    return ApiClient.patch('/api/teamlead/checkin',
        {'latitude': latitude, 'longitude': longitude});
  }

  static Future<Map<String, dynamic>> checkOut() {
    return ApiClient.patch('/api/teamlead/checkout', {});
  }

  static Future<Map<String, dynamic>> getHistory(String teamLeadId) {
    return ApiClient.get('/api/$teamLeadId/attendance-history');
  }
}