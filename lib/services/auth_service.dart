import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class AuthService {
  AuthService._();

  // ─── TRANSIENT FAILURE DETECTION ────────────────────────────
  // Used to decide whether a failed login probe is worth retrying.
  // Covers Render free-tier cold start timeouts, socket drops and
  // other transient network issues. 401/403/404 are NOT transient.
  static bool _isTransient(Map<String, dynamic> result) {
    final msg = result['message']?.toString().toLowerCase() ?? '';
    return msg.contains('timeout') ||
        msg.contains('socketexception') ||
        msg.contains('connection closed') ||
        msg.contains('connection reset') ||
        msg.contains('no internet') ||
        msg.contains('failed to fetch');
  }

  static Map<String, dynamic> normalizeLoginPayload(Map<dynamic, dynamic> data, String role) {
    final payload = Map<String, dynamic>.from(data);
    final email = payload['email']?.toString().trim().toLowerCase() ?? '';

    String userId = '';
    if (role == 'TEAM_LEAD') {
      userId = (payload['teamLeadId'] ?? payload['userId'] ?? payload['id'] ?? '').toString();
    } else if (role == 'STUDENT') {
      userId = (payload['studentId'] ?? payload['userId'] ?? payload['id'] ?? '').toString();
    } else if (role == 'OFFICE_STAFF') {
      userId = (payload['staffId'] ?? payload['userId'] ?? payload['id'] ?? '').toString();
    } else if (role == 'COLLEGE_STAFF') {
      userId = (payload['id'] ?? payload['collegeStaffId'] ?? payload['userId'] ?? '').toString();
    } else if (role == 'ADMIN') {
      userId = (payload['adminId'] ?? payload['userId'] ?? payload['id'] ?? '').toString();
    } else if (role == 'FREELANCER') {
      userId = (payload['freelancerId'] ?? payload['userId'] ?? payload['id'] ?? '').toString();
    }

    return {
      'token': payload['token']?.toString() ?? '',
      'role': role,
      'userId': userId,
      'name': payload['name']?.toString() ??
          payload['fullName']?.toString() ??
          payload['staffName']?.toString() ??
          email.split('@').first,
      'email': email,
      'category': payload['category']?.toString() ?? '',
      'profile': payload['profile']?.toString() ??
          payload['profilePhoto']?.toString() ??
          '',
    };
  }

  // ─── GENERIC LOGIN (try each role endpoint) ────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final normalisedEmail = email.trim().toLowerCase();

    final attempts = [
      {'path': '/api/teamlead/login', 'role': 'TEAM_LEAD'},
      {'path': '/api/admin/login', 'role': 'ADMIN'},
      {'path': '/api/collegestaff/login', 'role': 'COLLEGE_STAFF'},
      {'path': '/api/officestaff/login', 'role': 'OFFICE_STAFF'},
      {'path': '/api/student/login', 'role': 'STUDENT'},
      {'path': '/api/freelancer/login', 'role': 'FREELANCER'},
    ];

    Map<String, dynamic>? lastError;

    // Render free-tier instances sleep after ~15 min of idle time. The first
    // request after that triggers a cold boot that can take 60s+ before the
    // login endpoint responds, so give each role probe a generous timeout
    // instead of failing fast with a TimeoutException.
    const loginTimeout = Duration(seconds: 120);

    // All role endpoints are probed in parallel instead of one-by-one, so the
    // login only takes as long as the slowest single request (the correct one)
    // rather than summing the wait of every wrong-role attempt. This keeps the
    // login fast while still covering the deployed backend (Render free tier)
    // that cold-starts after idle time.
    for (var round = 0; round < 2; round++) {
      final results = await Future.wait(
        attempts.map((a) => ApiClient.post(
              a['path']!,
              {'email': normalisedEmail, 'password': password},
              auth: false,
              timeout: loginTimeout,
            )),
      );

      // 1. The first successful login wins.
      for (var i = 0; i < attempts.length; i++) {
        final result = results[i];
        final data = result['data'];
        if (result['success'] == true && data is Map) {
          final normalisedData = Map<dynamic, dynamic>.from(data);
          final emailVal = normalisedData['email'];
          if (emailVal != null) {
            normalisedData['email'] =
                emailVal.toString().trim().toLowerCase();
          }
          final normalized =
              normalizeLoginPayload(normalisedData, attempts[i]['role']!);
          if (normalized['token'].toString().isNotEmpty) {
            return {'success': true, 'data': normalized};
          }
          lastError = {
            'success': false,
            'message':
                data['message']?.toString() ?? 'Invalid email or password',
            'data': data,
          };
        } else {
          lastError = result;
        }
      }

      // 2. Retry once only when every attempt failed transiently (e.g. the
      //    instance is still cold-starting) instead of on a definite 401/404.
      final allTransient =
          results.isNotEmpty && results.every(_isTransient);
      if (!allTransient) break;
    }

    // If every probe still failed transiently (e.g. the instance was cold
    // starting for the whole attempt), collapse the raw TimeoutException text
    // into a clean, user-facing message instead of showing technical details.
    if (lastError != null && _isTransient(lastError)) {
      return {
        'success': false,
        'message': 'The server took too long to respond. '
            'Please check your internet connection and try again.',
      };
    }

    return lastError ??
        {'success': false, 'message': 'Invalid email or password'};
  }

  // ─── CHANGE PASSWORD ──────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    final email = await StorageHelper.getUserEmail();

    if (email == null || email.isEmpty) {
      return {
        'success': false,
        'message': 'Session expired. Please login again.'
      };
    }

    final role = await StorageHelper.getRole();

    if (role == 'TEAM_LEAD') {
      return ApiClient.patch(
        '/api/change-password',
        {
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    }

    final collegeResult = await ApiClient.post(
      '/api/collegestaff/change-password?email=$email&oldPassword=$oldPassword&newPassword=$newPassword',
      {},
      auth: false,
    );
    if (collegeResult['success'] == true) return collegeResult;

    final studentId = await StorageHelper.getUserId();
    if (studentId != null && studentId.isNotEmpty) {
      final studentResult = await ApiClient.patch(
        '/api/student/$studentId/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      if (studentResult['success'] == true) return studentResult;
    }

    return ApiClient.patch(
      '/api/officestaff/change-password',
      {
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  static Future<Map<String, dynamic>> _tryAdminForgotPassword(
      String endpoint, Map<String, dynamic>? body, String email,
      {String? otp, String? newPassword}) async {
    if (endpoint == 'send-otp') {
      return ApiClient.post('/api/admin/forgot-password/send-otp?email=$email', {},
          auth: false);
    }
    if (endpoint == 'verify-otp') {
      return ApiClient.post(
          '/api/admin/forgot-password/verify-otp?email=$email&otp=$otp', {},
          auth: false);
    }
    return ApiClient.post(
        '/api/admin/forgot-password/reset?email=$email&otp=$otp&newPassword=$newPassword',
        {},
        auth: false);
  }

  static Future<Map<String, dynamic>> _tryRoleForgotPassword(
      String role, String endpoint, Map<String, dynamic>? body, String email,
      {String? otp, String? newPassword}) async {
    if (role == 'ADMIN') {
      return _tryAdminForgotPassword(endpoint, body, email,
          otp: otp, newPassword: newPassword);
    }
    if (role == 'COLLEGE_STAFF') {
      if (endpoint == 'reset') {
        return ApiClient.post('/api/collegestaff/forgot-password/reset',
            {'email': email, 'otp': otp, 'newPassword': newPassword},
            auth: false);
      }
      return ApiClient.post(
          '/api/collegestaff/forgot-password/$endpoint?email=$email${otp != null ? '&otp=$otp' : ''}',
          {},
          auth: false);
    }
    if (role == 'OFFICE_STAFF') {
      if (endpoint == 'reset') {
        return ApiClient.post('/api/officestaff/forgot-password/reset',
            {'email': email, 'otp': otp, 'newPassword': newPassword},
            auth: false);
      }
      return ApiClient.post(
          '/api/officestaff/forgot-password/$endpoint?email=$email${otp != null ? '&otp=$otp' : ''}',
          {},
          auth: false);
    }
    if (role == 'TEAM_LEAD') {
      if (endpoint == 'reset') {
        return ApiClient.post('/api/forgot-password/reset',
            {'email': email, 'otp': otp, 'newPassword': newPassword},
            auth: false);
      }
      return ApiClient.post(
          '/api/forgot-password/$endpoint?email=$email${otp != null ? '&otp=$otp' : ''}',
          {},
          auth: false);
    }
    return {'success': false, 'message': 'Invalid role'};
  }

  // ─── FORGOT PASSWORD - SEND OTP ────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword(String email,
      {String? role}) async {
    if (role != null && role.isNotEmpty) {
      return _tryRoleForgotPassword(role, 'send-otp', null, email);
    }

    final adminResult = await _tryAdminForgotPassword('send-otp', null, email);
    if (adminResult['success'] == true) return adminResult;

    final collegeResult = await ApiClient.post(
      '/api/collegestaff/forgot-password/send-otp?email=$email',
      {},
      auth: false,
    );
    if (collegeResult['success'] == true) return collegeResult;
    final staffResult = await ApiClient.post(
      '/api/officestaff/forgot-password/send-otp?email=$email',
      {},
      auth: false,
    );
    if (staffResult['success'] == true) return staffResult;
    return ApiClient.post(
      '/api/forgot-password/send-otp?email=$email',
      {},
      auth: false,
    );
  }

  // ─── FORGOT PASSWORD - VERIFY OTP ────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp,
      {String? role}) async {
    if (role != null && role.isNotEmpty) {
      return _tryRoleForgotPassword(role, 'verify-otp', null, email, otp: otp);
    }

    final adminResult =
        await _tryAdminForgotPassword('verify-otp', null, email, otp: otp);
    if (adminResult['success'] == true) return adminResult;

    final collegeResult = await ApiClient.post(
      '/api/collegestaff/forgot-password/verify-otp?email=$email&otp=$otp',
      {},
      auth: false,
    );
    if (collegeResult['success'] == true) return collegeResult;
    final staffResult = await ApiClient.post(
      '/api/officestaff/forgot-password/verify-otp?email=$email&otp=$otp',
      {},
      auth: false,
    );
    if (staffResult['success'] == true) return staffResult;
    return ApiClient.post(
      '/api/forgot-password/verify-otp?email=$email&otp=$otp',
      {},
      auth: false,
    );
  }

  // ─── FORGOT PASSWORD - RESET ────────────────────────────────
  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword,
      {String? role}) async {
    if (role != null && role.isNotEmpty) {
      return _tryRoleForgotPassword(role, 'reset', null, email,
          otp: otp, newPassword: newPassword);
    }

    final adminResult = await _tryAdminForgotPassword('reset', null, email,
        otp: otp, newPassword: newPassword);
    if (adminResult['success'] == true) return adminResult;

    final collegeResult = await ApiClient.post(
      '/api/collegestaff/forgot-password/reset',
      {'email': email, 'otp': otp, 'newPassword': newPassword},
      auth: false,
    );
    if (collegeResult['success'] == true) return collegeResult;
    final staffResult = await ApiClient.post(
      '/api/officestaff/forgot-password/reset',
      {'email': email, 'otp': otp, 'newPassword': newPassword},
      auth: false,
    );
    if (staffResult['success'] == true) return staffResult;
    return ApiClient.post(
      '/api/forgot-password/reset',
      {'email': email, 'otp': otp, 'newPassword': newPassword},
      auth: false,
    );
  }
}