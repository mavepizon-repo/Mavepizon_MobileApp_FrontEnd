import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_certificate_service.dart';

class StudentCertificateProvider extends ChangeNotifier {
  List<dynamic> _certificates = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get certificates => _certificates;

  Future<void> fetchMyCertificates() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentCertificateService.getMyCertificates();
      if (result['success'] == true) {
        final data = result['data'];
        _certificates = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load certificates';
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

final studentCertificateProvider =
    ChangeNotifierProvider<StudentCertificateProvider>((ref) => StudentCertificateProvider());
