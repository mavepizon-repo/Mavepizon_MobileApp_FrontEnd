import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  List<dynamic> students = [];
  Map<String, dynamic>? selectedStudent;
  int totalStudentCount = 0;
  bool isLoading = false;
  String? error;

  // ─── FETCH ALL STUDENTS ───────────────────────────────────────
  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StudentService.getAll();

    if (result['success'] == true) {
      final data = result['data'];
      students = data is List ? data : [];
      totalStudentCount = students.length;
      error = null;
    } else {
      error = result['message'];
      students = [];
      totalStudentCount = 0;
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── FETCH STUDENT BY ID ──────────────────────────────────────
  Future<void> fetchById(String studentId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StudentService.getById(studentId);

    if (result['success'] == true) {
      selectedStudent = result['data'];
      error = null;
    } else {
      error = result['message'];
      selectedStudent = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── FETCH STUDENT BY CODE ────────────────────────────────────
  Future<void> fetchByCode(String studentCode) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StudentService.getByCode(studentCode);

    if (result['success'] == true) {
      selectedStudent = result['data'];
      error = null;
    } else {
      error = result['message'];
      selectedStudent = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── FETCH STUDENT BY EMAIL ───────────────────────────────────
  Future<void> fetchByEmail(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StudentService.getByEmail(email);

    if (result['success'] == true) {
      selectedStudent = result['data'];
      error = null;
    } else {
      error = result['message'];
      selectedStudent = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── CLEAR SELECTED ───────────────────────────────────────────
  void clearSelected() {
    selectedStudent = null;
    notifyListeners();
  }

  // ─── CLEAR ERROR ──────────────────────────────────────────────
  void clearError() {
    error = null;
    notifyListeners();
  }
}

final studentProvider = ChangeNotifierProvider<StudentProvider>((ref) => StudentProvider());
