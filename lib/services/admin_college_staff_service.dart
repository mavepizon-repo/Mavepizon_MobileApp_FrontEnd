import 'dart:typed_data';
import '../core/network/api_client.dart';

class AdminCollegeStaffService {
  AdminCollegeStaffService._();

  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/admin/college-staff');
  }

  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/admin/college-staff/$id');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) {
    return ApiClient.post('/api/admin/college-staff', data);
  }

  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) {
    return ApiClient.put('/api/admin/college-staff/$id', data);
  }

  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/admin/college-staff/$id');
  }

  // POST /api/college-staff/upload-syllabus?staffId=...
  // Backend expects multipart fields: "Syllabus" (the syllabus file) and
  // "Course" (the proposal file) -- controller maps Course -> proposal.
  static Future<Map<String, dynamic>> uploadSyllabus(
    String staffId, {
    required ({Uint8List bytes, String name}) syllabus,
    required ({Uint8List bytes, String name}) proposal,
  }) async {
    return ApiClient.uploadFiles(
      '/api/college-staff/upload-syllabus',
      {
        'Syllabus': syllabus,
        'Course': proposal,
      },
      queryParams: {'staffId': staffId},
    );
  }
}
