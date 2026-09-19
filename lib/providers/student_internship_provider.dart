import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_internship_service.dart';

class StudentInternshipProvider extends ChangeNotifier {
  List<dynamic> _internships = [];
  Map<String, dynamic>? _selectedInternship;
  List<dynamic> _myInternships = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get internships => _internships;
  Map<String, dynamic>? get selectedInternship => _selectedInternship;
  List<dynamic> get myInternships => _myInternships;

  Future<void> fetchAvailableInternships() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentInternshipService.getAvailableInternships();
      if (result['success'] == true) {
        final data = result['data'];
        _internships = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load internships';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchInternshipDetail(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentInternshipService.getInternshipDetail(id);
      if (result['success'] == true) {
        final data = result['data'];
        _selectedInternship = data is Map ? Map<String, dynamic>.from(data) : null;
      } else {
        error = result['message'] ?? 'Failed to load internship detail';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> applyForInternship(
      Map<String, dynamic> data) async {
    try {
      final result = await StudentInternshipService.applyForInternship(data);
      if (result['success'] == true) {
        final res = result['data'];
        if (res is Map) {
          await fetchMyInternships();
          return Map<String, dynamic>.from(res);
        }
        await fetchMyInternships();
        return <String, dynamic>{};
      } else {
        error = result['message'] ?? 'Application failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return null;
  }

  Future<void> fetchMyInternships() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentInternshipService.getMyInternships();
      if (result['success'] == true) {
        final data = result['data'];
        _myInternships = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load my internships';
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

final studentInternshipProvider =
    ChangeNotifierProvider<StudentInternshipProvider>((ref) => StudentInternshipProvider());
