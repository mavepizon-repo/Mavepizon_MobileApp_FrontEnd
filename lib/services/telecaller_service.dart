import '../core/network/api_client.dart';

class TelecallerService {
  TelecallerService._();

  static Future<Map<String, dynamic>> getEnquiries(String staffId,
      {int page = 0, int size = 20, String sort = 'id', String direction = 'asc'}) {
    return ApiClient.get(
      '/api/officestaff/telecalling/enquiry/all',
      queryParams: {
        'page': '$page',
        'size': '$size',
        'sort': sort,
        'direction': direction,
      },
    );
  }

  static Future<Map<String, dynamic>> getEnquiryById(
      String staffId, String enquiryId) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/$enquiryId');
  }

  static Future<Map<String, dynamic>> createEnquiry(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.post(
        '/api/officestaff/telecalling/enquiry/create', data);
  }

  static Future<Map<String, dynamic>> updateEnquiry(
      String staffId, String enquiryId, Map<String, dynamic> data) {
    return ApiClient.put(
        '/api/officestaff/telecalling/enquiry/update/$enquiryId', data);
  }

  static Future<Map<String, dynamic>> deleteEnquiry(
      String staffId, String enquiryId) {
    return ApiClient.delete(
        '/api/officestaff/telecalling/enquiry/delete/$enquiryId');
  }

  static Future<Map<String, dynamic>> filterByCollege(
      String staffId, String collegeName) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/college?college=$collegeName');
  }

  static Future<Map<String, dynamic>> filterByStatus(
      String staffId, String status) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/status?status=$status');
  }

  static Future<Map<String, dynamic>> filterByStudentName(
      String staffId, String studentName) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/student?studentName=$studentName');
  }

  static Future<Map<String, dynamic>> filterByDate(
      String staffId, String date) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/date?date=$date');
  }

  static Future<Map<String, dynamic>> getTodayFollowups(String staffId) {
    return ApiClient.get(
        '/api/officestaff/telecalling/enquiry/today-followups');
  }

  static Future<Map<String, dynamic>> getCustomFollowups(String staffId,
      {int page = 0, int size = 20, String sort = 'id', String direction = 'asc'}) {
    return ApiClient.get(
      '/api/officestaff/telecalling/custom-followups',
      queryParams: {
        'page': '$page',
        'size': '$size',
        'sort': sort,
        'direction': direction,
      },
    );
  }

  static Future<Map<String, dynamic>> addFollowup(
      String staffId, String enquiryId, Map<String, dynamic> data) {
    return ApiClient.post(
        '/api/officestaff/telecalling/followup/$enquiryId', data);
  }

  static Future<Map<String, dynamic>> getFollowupHistory(
      String staffId, String enquiryId) {
    return ApiClient.get(
        '/api/officestaff/telecalling/history/$enquiryId');
  }

  static Future<Map<String, dynamic>> updateEnquiryStatus(
      String staffId, String enquiryId, String status) {
    return ApiClient.put(
        '/api/officestaff/telecalling/update/$enquiryId/$status', {});
  }
}
