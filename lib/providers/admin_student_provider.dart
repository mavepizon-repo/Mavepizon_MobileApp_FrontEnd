import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../services/admin_student_service.dart';

class AdminStudentProvider extends ChangeNotifier {
  List<StudentModel> _students = [];
  StudentModel? _selected;
  bool isLoading = false;
  String? error;

  List<StudentModel> get students => _students;
  StudentModel? get selected => _selected;

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminStudentService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _students = data.map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          _students = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load students';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminStudentService.getById(id);
      if (result['success'] == true) {
        _selected = StudentModel.fromJson(Map<String, dynamic>.from(result['data']));
      } else {
        error = result['message'] ?? 'Failed to load student';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> searchByEmail(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminStudentService.getByEmail(email);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _students = data.map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (data is Map) {
          _students = [StudentModel.fromJson(Map<String, dynamic>.from(data))];
        } else {
          _students = [];
        }
      } else {
        error = result['message'] ?? 'No student found';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void clearSelected() {
    _selected = null;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminStudentProvider =
    ChangeNotifierProvider<AdminStudentProvider>((ref) => AdminStudentProvider());
