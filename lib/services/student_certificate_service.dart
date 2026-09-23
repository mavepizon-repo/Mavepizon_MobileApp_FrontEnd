import '../core/network/api_client.dart';

class StudentCertificateService {
  StudentCertificateService._();

  // GET /api/certificates/student/{studentId}
  // Backend expects the numeric DB id (Long). That numeric id is only exposed
  // inside the my-courses payload (student.id), so derive it from there when
  // the caller does not already have it.
  static Future<Map<String, dynamic>> getMyCertificates(
      {String? dbStudentId}) async {
    final dbId = dbStudentId ?? await _resolveDbStudentId();
    if (dbId != null && dbId.isNotEmpty) {
      return ApiClient.get('/api/certificates/student/$dbId');
    }

    // The backend only accepts the numeric DB student id, which is only
    // resolvable from a course registration. A student without any
    // registration cannot own certificates yet, so return an empty list
    // instead of hitting the endpoint with a non-numeric business id.
    return {'success': true, 'data': <dynamic>[]};
  }

  static Future<String?> _resolveDbStudentId() async {
    final result = await ApiClient.get('/api/student-course/my-courses');
    if (result['success'] != true) return null;
    final data = result['data'];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final student = item['student'];
          if (student is Map) {
            final id = student['id'];
            if (id != null) return id.toString();
          }
        }
      }
    }
    return null;
  }
}