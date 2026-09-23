import '../core/network/api_client.dart';

class AdminStudentService {
  AdminStudentService._();

  static Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'asc',
    String? search,
  }) {
    return ApiClient.get('/api/admin/students', queryParams: {
      'page': '$page',
      'size': '$size',
      'sort': sort,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
    });
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
