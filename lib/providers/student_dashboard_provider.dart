import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_course_service.dart';
import '../services/student_internship_service.dart';
import '../services/student_certificate_service.dart';
import '../services/student_payment_service.dart';

class StudentDashboardProvider extends ChangeNotifier {
  int _courseCount = 0;
  int _internshipCount = 0;
  int _paymentCount = 0;
  int _certificateCount = 0;
  List<dynamic> _availableCourses = [];
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
      _courseCount = data is List ? data.length : 0;
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

    try {
      final payments = await StudentPaymentService.getPaymentsByRegistration('');
      if (payments['success'] == true) {
        final data = payments['data'];
        _paymentCount = data is List ? data.length : 0;
      } else {
        _paymentCount = _courseCount;
      }
    } catch (_) {
      _paymentCount = _courseCount;
    }

    final certs = await StudentCertificateService.getMyCertificates();
    if (certs['success'] == true) {
      final data = certs['data'];
      _certificateCount = data is List ? data.length : 0;
    } else {
      errs.add('Certificates: ${certs['message']}');
    }

    final available = await StudentCourseService.getAvailableCourses();
    if (available['success'] == true) {
      final data = available['data'];
      _availableCourses = data is List ? data : [];
    }

    if (errs.isNotEmpty && _courseCount == 0 && _internshipCount == 0 && _paymentCount == 0 && _certificateCount == 0) {
      error = errs.join('\n');
    }

    isLoading = false;
    notifyListeners();
  }
}

final studentDashboardProvider =
    ChangeNotifierProvider<StudentDashboardProvider>((ref) => StudentDashboardProvider());
