import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_course_service.dart';

class StudentCourseProvider extends ChangeNotifier {
  List<dynamic> _courses = [];
  Map<String, dynamic>? _selectedCourse;
  List<dynamic> _myCourses = [];
  Map<String, dynamic>? _registrationResult;
  bool isLoading = false;
  String? error;

  List<dynamic> get courses => _courses;
  Map<String, dynamic>? get selectedCourse => _selectedCourse;
  List<dynamic> get myCourses => _myCourses;
  Map<String, dynamic>? get registrationResult => _registrationResult;

  Future<void> fetchAvailableCourses() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentCourseService.getAvailableCourses();
      if (result['success'] == true) {
        final data = result['data'];
        // /api/course/get-all returns BOTH courses and internships; keep only
        // the category == COURSE entries in the student course list.
        _courses = data is List
            ? (data.where((e) =>
                    e is Map &&
                    (e['category']?.toString() ?? '').toUpperCase() ==
                        'COURSE')
                .toList())
            : [];
      } else {
        error = result['message'] ?? 'Failed to load courses';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCourseDetail(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentCourseService.getCourseDetail(id);
      if (result['success'] == true) {
        final data = result['data'];
        _selectedCourse = data is Map ? Map<String, dynamic>.from(data) : null;
      } else {
        error = result['message'] ?? 'Failed to load course detail';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  // POST /api/student-course/register
  // Body: { courseId, mode, location }
  Future<Map<String, dynamic>?> registerForCourse(Map<String, dynamic> data) async {
    _registrationResult = null;
    try {
      final result = await StudentCourseService.registerForCourse(data);
      if (result['success'] == true) {
        final res = result['data'];
        _registrationResult =
            res is Map ? Map<String, dynamic>.from(res) : null;
        await fetchMyCourses();
        return _registrationResult;
      } else {
        error = result['message'] ?? 'Registration failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return null;
  }

  // PATCH /api/student-course/update/{registrationId}
  // Update mode/location ONLY before payment.
  Future<bool> updateRegistrationMode(
      String registrationId, Map<String, dynamic> data) async {
    try {
      final result =
          await StudentCourseService.updateRegistrationMode(registrationId, data);
      if (result['success'] == true) {
        await fetchMyCourses();
        return true;
      } else {
        error = result['message'] ?? 'Update failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<void> fetchMyCourses() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentCourseService.getMyCourses();
      if (result['success'] == true) {
        final data = result['data'];
        _myCourses = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load my courses';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final studentCourseProvider =
    ChangeNotifierProvider<StudentCourseProvider>((ref) => StudentCourseProvider());
