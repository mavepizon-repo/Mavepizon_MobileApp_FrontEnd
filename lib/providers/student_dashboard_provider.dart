import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_course_service.dart';
import '../services/student_internship_service.dart';
import '../services/student_certificate_service.dart';
import '../core/utils/course_utils.dart';

class StudentDashboardProvider extends ChangeNotifier {
  int _courseCount = 0;
  int _internshipCount = 0;
  int _paymentCount = 0;
  int _certificateCount = 0;
  List<dynamic> _availableCourses = [];
  String? _dbStudentId;
  bool isLoading = false;
  String? error;

  int get courseCount => _courseCount;
  int get internshipCount => _internshipCount;
  int get paymentCount => _paymentCount;
  int get certificateCount => _certificateCount;
  List<dynamic> get availableCourses => _availableCourses;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final errs = <String>[];

    final courses = await StudentCourseService.getMyCourses();
    if (courses['success'] == true) {
      final data = courses['data'];
      final list = data is List ? data : <dynamic>[];
      _courseCount = list.length;
      _paymentCount = _countPaidRegistrations(list);
      _dbStudentId = _extractDbStudentId(list);
    } else {
      errs.add('Courses: ${courses['message']}');
    }

    final myInternships = await StudentInternshipService.getMyInternships();
    if (myInternships['success'] == true) {
      final data = myInternships['data'];
      _internshipCount = data is List ? data.length : 0;
    } else {
      errs.add('Internships: ${myInternships['message']}');
    }

    final certs = await StudentCertificateService.getMyCertificates(
      dbStudentId: _dbStudentId,
    );
    if (certs['success'] == true) {
      final data = certs['data'];
      _certificateCount = data is List ? data.length : 0;
    } else {
      errs.add('Certificates: ${certs['message']}');
    }

    final available = await StudentCourseService.getAvailableCourses();
    if (available['success'] == true) {
      final data = available['data'];
      // /api/course/get-all returns a Spring Page ({content: [...]}), NOT a
      // plain List. Accept both shapes and keep only COURSE entries.
      var list = <dynamic>[];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final content = data['content'];
        if (content is List) list = content;
      }
      _availableCourses = list
          .where((e) =>
              e is Map &&
              (e['category']?.toString() ?? '').toUpperCase() == 'COURSE' &&
              isOfferedCourse(e))
          .toList();
    }

    if (errs.isNotEmpty && _courseCount == 0 && _internshipCount == 0 && _paymentCount == 0 && _certificateCount == 0) {
      error = errs.join('\n');
    }

    isLoading = false;
    notifyListeners();
  }

  String? _extractDbStudentId(List<dynamic> registrations) {
    for (final r in registrations) {
      if (r is Map) {
        final student = r['student'];
        if (student is Map) {
          final id = student['id'];
          if (id != null) return id.toString();
        }
      }
    }
    return null;
  }

  int _countPaidRegistrations(List<dynamic> registrations) {
    var count = 0;
    for (final r in registrations) {
      if (r is Map) {
        final status =
            (r['paymentStatus']?.toString() ?? '').toUpperCase();
        if (status == 'PAID' ||
            status == 'SUCCESS' ||
            status == 'COMPLETED') {
          count++;
        }
      }
    }
    return count;
  }
}

final studentDashboardProvider =
    ChangeNotifierProvider<StudentDashboardProvider>((ref) => StudentDashboardProvider());
