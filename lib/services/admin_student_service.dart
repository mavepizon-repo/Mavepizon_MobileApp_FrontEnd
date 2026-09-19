import '../core/network/api_client.dart';

class AdminStudentService {
  AdminStudentService._();

  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/admin/students');
  }

  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/admin/students/$id');
  }

  static Future<Map<String, dynamic>> getByEmail(String email) {
    return ApiClient.get('/api/admin/students/email?email=$email');
  }

  static Future<Map<String, dynamic>> getByStudentCode(String code) {
    return ApiClient.get('/api/admin/students/code/$code');
  }
}
