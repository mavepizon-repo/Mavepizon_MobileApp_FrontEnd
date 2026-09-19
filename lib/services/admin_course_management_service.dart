import '../core/network/api_client.dart';

class AdminCourseManagementService {
  AdminCourseManagementService._();

  // ─── OFFERED COURSE CRUD ───────────────────────────────────────

  // POST /api/course/create
  static Future<Map<String, dynamic>> createOfferedCourse(
      Map<String, dynamic> data) {
    return ApiClient.post('/api/course/create', data);
  }

  // GET /api/course/get-all
  static Future<Map<String, dynamic>> getAllOfferedCourses() {
    return ApiClient.get('/api/course/get-all');
  }

  // GET /api/course/get/id/{id}
  static Future<Map<String, dynamic>> getOfferedCourseById(String id) {
    return ApiClient.get('/api/course/get/id/$id');
  }

  // PUT /api/course/update/{id}
  static Future<Map<String, dynamic>> updateOfferedCourse(
      String id, Map<String, dynamic> data) {
    return ApiClient.put('/api/course/update/$id', data);
  }

  // DELETE /api/course/delete/{id}
  static Future<Map<String, dynamic>> deleteOfferedCourse(String id) {
    return ApiClient.delete('/api/course/delete/$id');
  }

  // ─── STUDENT COURSE REGISTRATION MANAGEMENT ────────────────────

  // GET /api/student-course/get-all
  static Future<Map<String, dynamic>> getAllRegistrations() {
    return ApiClient.get('/api/student-course/get-all');
  }

  // GET /api/student-course/get/{id}
  static Future<Map<String, dynamic>> getRegistrationById(String id) {
    return ApiClient.get('/api/student-course/get/$id');
  }

  // GET /api/student-course/student/{studentId}
  static Future<Map<String, dynamic>> getRegistrationsByStudent(
      String studentId) {
    return ApiClient.get('/api/student-course/student/$studentId');
  }

  // DELETE /api/student-course/delete/{id}
  static Future<Map<String, dynamic>> deleteRegistration(String id) {
    return ApiClient.delete('/api/student-course/delete/$id');
  }
}