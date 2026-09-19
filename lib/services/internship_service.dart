import '../core/network/api_client.dart';

class InternshipService {
  InternshipService._();

  // ─── GET ALL INTERNSHIPS ──────────────────────────────────────
  static Future<Map<String, dynamic>> getAll() async {
    return ApiClient.get('/api/internship/get-all');
  }

  // ─── GET BY ID ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getById(String id) async {
    return ApiClient.get('/api/internship/get/$id');
  }

  // ─── CREATE INTERNSHIP ────────────────────────────────────────
  // Internships use the shared course payload shape (name, fees, seats, dates).
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final body = _buildBody(data);
    return ApiClient.post('/api/internship/create', body);
  }

  // ─── UPDATE INTERNSHIP ────────────────────────────────────────
  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final body = _buildBody(data);
    return ApiClient.put('/api/internship/update/$id', body);
  }

  // ─── DELETE INTERNSHIP ────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String id) async {
    return ApiClient.delete('/api/internship/delete/$id');
  }

  // ─── TOGGLE STATUS ────────────────────────────────────────────
  // PATCH /api/internship/{id}/status?status=ACTIVE|INACTIVE|CLOSED
  static Future<Map<String, dynamic>> toggleStatus(
      String id, String status) async {
    return ApiClient.patch('/api/internship/$id/status?status=$status', {});
  }

  // ─── BODY BUILDER ─────────────────
  static Map<String, dynamic> _buildBody(Map<String, dynamic> data) {
    final body = <String, dynamic>{
      'courseName': data['internshipName'] ?? data['courseName'] ?? '',
      'description': data['description'] ?? '',
      'duration': data['duration'] ?? '',
      'totalFees': data['totalFees'] ?? data['fees'] ?? 0,
      'totalSeatsOnline': data['totalSeatsOnline'] ?? 0,
      'totalSeatsOffline': data['totalSeatsOffline'] ?? 0,
      'totalSeatsTirunelveli': data['totalSeatsTirunelveli'] ?? 0,
      'totalSeatsTisaiyanvilai': data['totalSeatsTisaiyanvilai'] ?? 0,
      if (data['status'] != null && data['status'].toString().isNotEmpty)
        'status': data['status'],
      if (data['category'] != null && data['category'].toString().isNotEmpty)
        'category': data['category'],
    };

    _putDateIfPresent(body, 'startDate', data['startDate']);
    _putDateIfPresent(body, 'endDate', data['endDate']);
    _putDateIfPresent(
        body, 'registrationStartDate', data['registrationStartDate']);
    _putDateIfPresent(
        body, 'registrationEndDate', data['registrationEndDate']);

    return body;
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