import '../core/network/api_client.dart';

class AdminHolidayService {
  AdminHolidayService._();

  /// Marks the given date as an OD holiday for ALL office staff.
  /// Backend: `@PatchMapping("/mark-holiday/officeStaff/all")` with `?date=`.
  static Future<Map<String, dynamic>> markHoliday(String date) {
    return ApiClient.patch('/api/admin/mark-holiday/officeStaff/all?date=$date', {});
  }

  /// Marks the given date as an OD holiday for ALL team leads.
  /// Backend: `@PatchMapping("/mark-holiday/teamlead/all")` with `?date=`.
  static Future<Map<String, dynamic>> markTeamLeadHoliday(String date) {
    return ApiClient.patch('/api/admin/mark-holiday/teamlead/all?date=$date', {});
  }

  /// Marks the given date as an OD holiday for a single team lead by ID.
  /// Backend: `@PatchMapping("/mark-holiday/teamlead/{teamleadId}")` with `?date=`.
  static Future<Map<String, dynamic>> markTeamLeadHolidayById(
      String teamLeadId, String date) {
    return ApiClient.patch('/api/admin/mark-holiday/teamlead/$teamLeadId?date=$date', {});
  }

  /// Marks the given date as an OD holiday for a single office staff by ID.
  /// Backend: `@PatchMapping("/mark-holiday/officeStaff/{staffId}")` with `?date=`.
  static Future<Map<String, dynamic>> markStaffHolidayById(
      String staffId, String date) {
    return ApiClient.patch('/api/admin/mark-holiday/officeStaff/$staffId?date=$date', {});
  }

  /// Backend: `@PostMapping("/schedule/saturday-working")` with `?date=`.
  static Future<Map<String, dynamic>> setSaturdayWorking(String date) {
    return ApiClient.post('/api/admin/schedule/saturday-working?date=$date', {});
  }
}
