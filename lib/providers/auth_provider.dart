import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../core/utils/storage_helper.dart';
import '../routes/app_routes.dart';

class AuthProvider extends ChangeNotifier {
  String? role;
  String? userId;
  String? userName;
  String? userEmail;
  String? staffCategory;
  String? userProfile;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => role != null && userId != null;
  bool get isTeamLead => role == 'TEAM_LEAD';
  bool get isStudent => role == 'STUDENT';
  bool get isAdmin => role == 'ADMIN';
  bool get isStaff => role == 'OFFICE_STAFF';
  bool get isCollegeStaff => role == 'COLLEGE_STAFF';
  bool get isFreelancer => role == 'FREELANCER';

  // ─── LOGIN (tries all roles) ───────────────────────────────────
  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result['success'] == true) {
        final data = result['data'];
        await StorageHelper.saveLoginData(
          token: data['token'] ?? '',
          role: data['role'] ?? 'STAFF',
          userId: data['adminId']?.toString() ?? data['userId']?.toString() ?? '',
          userName: data['name'] ?? '',
          userEmail: data['email'] ?? '',
          staffCategory: data['category']?.toString() ?? '',
          userProfile: data['profile']?.toString() ?? '',
        );
        if ((data['role'] ?? '').toString() == 'STUDENT') {
          await _refreshStoredStudentProfile(data);
        }
        await loadUser();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Login failed. Please check your credentials.';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'Network error: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // The student login response only carries token/role/id/email, so on every
  // login the real (possibly updated) name and profile photo are pulled from
  // the backend self endpoints and re-saved, keeping them stable across
  // logout/login cycles.
  Future<void> _refreshStoredStudentProfile(Map<String, dynamic> data) async {
    String name = data['name']?.toString() ?? '';
    String profile = data['profile']?.toString() ?? '';

    final dash = await StudentService.getDashboard();
    if (dash['success'] == true && dash['data'] is Map) {
      final dashMap = dash['data'] as Map;
      final dashName = dashMap['name']?.toString() ?? '';
      if (dashName.isNotEmpty) name = dashName;
      final dashStudentId = dashMap['studentId']?.toString() ?? '';
      if (dashStudentId.isNotEmpty) data['userId'] = dashStudentId;
    }

    final files = await StudentService.getFiles();
    if (files['success'] == true && files['data'] is Map) {
      final fileMap = files['data'] as Map;
      final photo = fileMap['profilePhoto']?.toString() ??
          fileMap['profile']?.toString() ??
          '';
      if (photo.isNotEmpty) profile = photo;
    }

    await StorageHelper.saveLoginData(
      token: data['token']?.toString() ?? '',
      role: 'STUDENT',
      userId: data['userId']?.toString() ?? '',
      userName: name,
      userEmail: data['email']?.toString() ?? '',
      userProfile: profile,
    );
  }

  // ─── LOAD USER FROM STORAGE ──────────────────────────────────
  Future<void> loadUser() async {
    role = await StorageHelper.getRole();
    userId = await StorageHelper.getUserId();
    userName = await StorageHelper.getUserName();
    userEmail = await StorageHelper.getUserEmail();
    staffCategory = await StorageHelper.getStaffCategory();
    userProfile = await StorageHelper.getUserProfile();
    notifyListeners();
  }

  // ─── LOGOUT ─────────────────────────────────────────────────────
  Future<void> logout() async {
    await StorageHelper.clearAll();
    role = null;
    userId = null;
    userName = null;
    userEmail = null;
    staffCategory = null;
    userProfile = null;
    notifyListeners();
  }

  // ─── CHANGE PASSWORD ──────────────────────────────────────────
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AuthService.changePassword(oldPassword, newPassword);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to change password';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'Network error: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── GET HOME ROUTE BASED ON ROLE ────────────────────────────
  String getHomeRoute() {
    if (role == 'TEAM_LEAD') {
      return AppRoutes.teamLeadMain;
    }
    if (role == 'ADMIN') {
      return AppRoutes.adminMain;
    }
    if (role == 'OFFICE_STAFF') {
      return AppRoutes.staffMain;
    }
    if (role == 'STUDENT') {
      return AppRoutes.studentMain;
    }
    if (role == 'COLLEGE_STAFF') {
      return AppRoutes.collegeStaffMain;
    }
    if (role == 'FREELANCER') {
      return AppRoutes.freelancerMain;
    }
    return AppRoutes.login;
  }
}

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());
