import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/student_model.dart';
import '../services/admin_student_service.dart';

class AdminStudentProvider extends ChangeNotifier {
  List<StudentModel> _students = [];
  StudentModel? _selected;
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

  List<StudentModel> get students => _students;
  StudentModel? get selected => _selected;
  PaginationData get pagination => PaginationData(
        page: currentPage,
        totalPages: totalPages,
        totalElements: totalElements,
        size: pageSize,
      );

  Future<void> fetchAll({int page = 0, int size = 20, String? search}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await AdminStudentService.getAll(page: page, size: size, search: search);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        _students = pageData
            .map<StudentModel>(
                (e) => StudentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load students';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchAll(
      page: currentPage, size: pageSize, search: _searchQuery);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String q) {
    _searchQuery = q.trim();
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
