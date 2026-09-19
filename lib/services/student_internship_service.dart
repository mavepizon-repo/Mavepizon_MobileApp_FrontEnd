import '../core/network/api_client.dart';

class StudentInternshipService {
  StudentInternshipService._();

  static Future<Map<String, dynamic>> getAvailableInternships() {
    return ApiClient.get('/api/internship/get-all');
  }

  static Future<Map<String, dynamic>> getInternshipDetail(String id) {
    return ApiClient.get('/api/internship/get/$id');
  }

  // POST /api/student-internship/register  body: {courseId, mode, location}
  static Future<Map<String, dynamic>> applyForInternship(
      Map<String, dynamic> data) {
    return ApiClient.post('/api/student-internship/register', data);
  }

  static Future<Map<String, dynamic>> getMyInternships() {
    return ApiClient.get('/api/student-internship/my-internships');
  }
}