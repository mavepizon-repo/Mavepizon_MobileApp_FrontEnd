import '../core/network/api_client.dart';

class StudentCourseService {
  StudentCourseService._();

  // GET /api/course/get-all (public, paginated)
  static Future<Map<String, dynamic>> getAvailableCourses(
      {int page = 0, int size = 20}) {
    return ApiClient.get(
      '/api/course/get-all',
      queryParams: {'page': '$page', 'size': '$size'},
    );
  }

  static Future<Map<String, dynamic>> getAllCourses(
      {int page = 0, int size = 20}) {
    return ApiClient.get(
      '/api/course/get-all',
      queryParams: {'page': '$page', 'size': '$size'},
    );
  }

  // GET /api/course/get/id/{id}
  static Future<Map<String, dynamic>> getCourseDetail(String id) {
    return ApiClient.get('/api/course/get/id/$id');
  }

  // POST /api/student-course/register
  // Body: { courseId, mode (ONLINE|OFFLINE), location (TIRUNELVELI|TISAIYANVILAI) }
  static Future<Map<String, dynamic>> registerForCourse(
      Map<String, dynamic> data) {
    return ApiClient.post('/api/student-course/register', data);
  }

  // PATCH /api/student-course/update/{registrationId}
  // Update mode/location ONLY before payment.
  static Future<Map<String, dynamic>> updateRegistrationMode(
      String registrationId, Map<String, dynamic> data) {
    return ApiClient.patch('/api/student-course/update/$registrationId', data);
  }

  // GET /api/student-course/my-courses
  static Future<Map<String, dynamic>> getMyCourses() {
    return ApiClient.get('/api/student-course/my-courses');
  }

  // GET /api/student-course/get-all (admin/staff)
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

  // GET /api/student-course/course/{courseId}
  static Future<Map<String, dynamic>> getRegistrationsByCourse(
      String courseId) {
    return ApiClient.get('/api/student-course/course/$courseId');
  }

  // DELETE /api/student-course/delete/{id}
  static Future<Map<String, dynamic>> deleteRegistration(String id) {
    return ApiClient.delete('/api/student-course/delete/$id');
  }
}
