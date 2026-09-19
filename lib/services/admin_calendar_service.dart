import '../core/network/api_client.dart';

class AdminCalendarService {
  AdminCalendarService._();

  static Future<Map<String, dynamic>> getLeaves(String startDate, String endDate) {
    return ApiClient.get(
      '/api/admin/calendar/leaves',
      queryParams: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }
}
