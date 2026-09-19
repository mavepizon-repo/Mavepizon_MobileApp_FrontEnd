import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StudentService {
  StudentService._();

  // ─── GET ALL STUDENTS ─────────────────────────────────────────
  // GET /api/{teamLeadId}/students
  static Future<Map<String, dynamic>> getAll() async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/$teamLeadId/students');
  }

  // ─── GET STUDENT BY ID ────────────────────────────────────────
  // GET /api/{teamLeadId}/students/{studentId}
  static Future<Map<String, dynamic>> getById(String studentId) async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get('/api/$teamLeadId/students/$studentId');
  }

  // ─── GET STUDENT BY CODE ──────────────────────────────────────
  // GET /api/{teamLeadId}/students/code/{studentId}
  static Future<Map<String, dynamic>> getByCode(String studentCode) async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get(
        '/api/$teamLeadId/students/code/$studentCode');
  }

  // ─── GET STUDENT BY EMAIL ─────────────────────────────────────
  // GET /api/{teamLeadId}/students/email?email=
  static Future<Map<String, dynamic>> getByEmail(String email) async {
    final teamLeadId = await StorageHelper.getUserId();
    return ApiClient.get(
      '/api/$teamLeadId/students/email',
      queryParams: {'email': email},
    );
  }

  // ─── REGISTER ──────────────────────────────────────────────────
  // POST /api/student/register
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) {
    return ApiClient.post('/api/student/register', data, auth: false);
  }

  // ─── UPDATE PROFILE (self) ────────────────────────────────────
  // PUT /api/student/update/{studentId}
  static Future<Map<String, dynamic>> updateProfile(
      String studentId, Map<String, dynamic> data) {
    return ApiClient.put('/api/student/update/$studentId', data);
  }

  // ─── FORGOT PASSWORD SEND OTP ─────────────────────────────────
  // POST /api/student/forgot-password/send-otp?email=
  static Future<Map<String, dynamic>> forgotPasswordSendOtp(
      String email) {
    return ApiClient.post(
        '/api/student/forgot-password/send-otp?email=$email', {});
  }

  // ─── FORGOT PASSWORD VERIFY OTP ───────────────────────────────
  // POST /api/student/forgot-password/verify-otp?email=&otp=
  static Future<Map<String, dynamic>> forgotPasswordVerifyOtp(
      String email, String otp) {
    return ApiClient.post(
        '/api/student/forgot-password/verify-otp?email=$email&otp=$otp',
        {});
  }

  // ─── FORGOT PASSWORD RESET ────────────────────────────────────
  // POST /api/student/forgot-password/reset?email=&otp=&newPassword=
  static Future<Map<String, dynamic>> forgotPasswordReset(
      String email, String otp, String newPassword) {
    return ApiClient.post(
        '/api/student/forgot-password/reset?email=$email&otp=$otp&newPassword=$newPassword',
        {});
  }

  // ─── GET LEAVE HISTORY (TL) ───────────────────────────────────
  // GET /api/{teamLeadId}/leave-history
  static Future<Map<String, dynamic>> getLeaveHistory(
      String teamLeadId) {
    return ApiClient.get('/api/$teamLeadId/leave-history');
  }

  // ─── GET ALL STAFF LEAVES ─────────────────────────────────────
  // GET /api/office-staff/leave
  static Future<Map<String, dynamic>> getLeaveUsers() {
    return ApiClient.get('/api/office-staff/leave');
  }
}