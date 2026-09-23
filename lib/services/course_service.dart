import '../core/network/api_client.dart';

class CourseService {
  CourseService._();

  // ─── GET ALL COURSES ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getAll(
      {int page = 0, int size = 20}) {
    return ApiClient.get(
      '/api/course/get-all',
      queryParams: {'page': '$page', 'size': '$size'},
    );
  }

  // ─── GET COURSE BY ID ─────────────────────────────────────────
  static Future<Map<String, dynamic>> getById(String id) async {
    return ApiClient.get('/api/course/get/id/$id');
  }

  // ─── GET COURSE BY CODE ───────────────────────────────────────
  static Future<Map<String, dynamic>> getByCode(String courseCode) async {
    return ApiClient.get('/api/course/get/code/$courseCode');
  }

  // ─── CREATE COURSE ────────────────────────────────────────────
  // POST /api/course/create  (Admin / Team Lead, Bearer token)
  //
  // Date fields must never be sent as an empty string '' — only include a
  // date key when it has a real value, so a missing required date is omitted
  // rather than sent blank.
  //
  // Seat keys use totalSeatsTirunelveli / totalSeatsTisaiyanvilai.
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final body = <String, dynamic>{
      'courseName': data['courseName'] ?? '',
      'description': data['description'] ?? '',
      'duration': data['duration'] ?? '',
      'totalFees': data['totalFees'] ?? data['fees'] ?? 0,
      'totalSeatsOnline': data['totalSeatsOnline'] ?? 0,
      'totalSeatsOffline': data['totalSeatsOffline'] ?? 0,
      'totalSeatsTirunelveli': data['totalSeatsTirunelveli'] ?? 0,
      'totalSeatsTisaiyanvilai': data['totalSeatsTisaiyanvilai'] ?? 0,
      if (data['category'] != null && data['category'].toString().isNotEmpty)
        'category': data['category'],
      if (data['locations'] != null) 'locations': data['locations'],
    };

    _putDateIfPresent(body, 'startDate', data['startDate']);
    _putDateIfPresent(body, 'endDate', data['endDate']);
    _putDateIfPresent(
        body, 'registrationStartDate', data['registrationStartDate']);
    _putDateIfPresent(
        body, 'registrationEndDate', data['registrationEndDate']);

    return ApiClient.post('/api/course/create', body);
  }

  // ─── UPDATE COURSE ────────────────────────────────────────────
  // PUT /api/course/update/{id}
  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final body = <String, dynamic>{
      'courseName': data['courseName'] ?? '',
      'description': data['description'] ?? '',
      'duration': data['duration'] ?? '',
      'totalFees': data['totalFees'] ?? data['fees'] ?? 0,
      'totalSeatsOnline': data['totalSeatsOnline'] ?? 0,
      'totalSeatsOffline': data['totalSeatsOffline'] ?? 0,
      'totalSeatsTirunelveli': data['totalSeatsTirunelveli'] ?? 0,
      'totalSeatsTisaiyanvilai': data['totalSeatsTisaiyanvilai'] ?? 0,
      if (data['category'] != null && data['category'].toString().isNotEmpty)
        'category': data['category'],
      if (data['locations'] != null) 'locations': data['locations'],
    };

    _putDateIfPresent(body, 'startDate', data['startDate']);
    _putDateIfPresent(body, 'endDate', data['endDate']);
    _putDateIfPresent(
        body, 'registrationStartDate', data['registrationStartDate']);
    _putDateIfPresent(
        body, 'registrationEndDate', data['registrationEndDate']);

    return ApiClient.put('/api/course/update/$id', body);
  }

  // ─── DELETE COURSE ────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String id) async {
    return ApiClient.delete('/api/course/delete/$id');
  }

  // ─── TOGGLE STATUS ────────────────────────────────────────────
  static Future<Map<String, dynamic>> toggleStatus(
      String id, String status) async {
    return ApiClient.patch('/api/course/$id/status?status=$status', {});
  }

  // ─── HELPER: only add a date key when it actually has a value ──
  static void _putDateIfPresent(
      Map<String, dynamic> body, String key, dynamic rawValue) {
    final formatted = _dateOnly(rawValue?.toString() ?? '');
    if (formatted.isNotEmpty) {
      body[key] = formatted;
    }
  }

  // ─── HELPER: yyyy-MM-dd ───────────────────────────────────────
  static String _dateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    if (dateStr.contains('T')) return dateStr.split('T').first;
    return dateStr;
  }
}