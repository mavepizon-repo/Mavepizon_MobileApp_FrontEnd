import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  List<dynamic> students = [];
  Map<String, dynamic>? selectedStudent;
  int totalStudentCount = 0;
  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;
  bool isLoading = false;
  String? error;

  PaginationData get pagination => PaginationData(
        page: currentPage,
        totalPages: totalPages,
        totalElements: totalElements,
        size: pageSize,
      );

  // ─── FETCH ALL STUDENTS ───────────────────────────────────────
  Future<void> fetchAll({int page = 0, int size = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StudentService.getAll(page: page, size: size);

    if (result['success'] == true) {
      final data = result['data'];
      // Backend returns a Spring Page ({content, totalElements, ...});
      // keep the plain-List fallback for resilient parsing.
      final pageData = PaginationData.parse(data);
      students = pageData.content;
      currentPage = pageData.page;
      totalPages = pageData.totalPages;
      totalElements = pageData.totalElements;
      if (pageData.size > 0) pageSize = pageData.size;
      totalStudentCount = pageData.totalElements;
      error = null;
    } else {
      error = result['message'];
      students = [];
      totalStudentCount = 0;
      currentPage = 0;
      totalPages = 1;
      totalElements = 0;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchAll(page: currentPage, size: pageSize);

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
