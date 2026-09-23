import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/college_staff_model.dart';
import '../services/admin_college_staff_service.dart';

class AdminCollegeStaffProvider extends ChangeNotifier {
  List<CollegeStaffModel> _list = [];
  CollegeStaffModel? _selected;
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

  List<CollegeStaffModel> get list => _list;
  CollegeStaffModel? get selected => _selected;
  PaginationData get pagination => PaginationData(
        page: currentPage,
        totalPages: totalPages,
        totalElements: totalElements,
        size: pageSize,
      );

  Future<void> fetch({int page = 0, int size = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await AdminCollegeStaffService.getAll(page: page, size: size);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        _list = pageData
            .map<CollegeStaffModel>((e) => CollegeStaffModel.fromJson(e))
            .toList();
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load college staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetch(page: currentPage, size: pageSize);

  Future<void> fetchById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.getById(id);
      if (result['success'] == true) {
        _selected = CollegeStaffModel.fromJson(result['data']);
      } else {
        error = result['message'] ?? 'Failed to load college staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.create(data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        await refresh();
        return true;
      } else {
        error = result['message'] ?? 'Failed to create';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.update(id, data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        await refresh();
        return true;
      } else {
        error = result['message'] ?? 'Failed to update';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> delete(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.delete(id);
      if (result['success'] == true) {
        await refresh();
        if (_list.isEmpty && currentPage > 0) {
          await fetch(page: currentPage - 1, size: pageSize);
        }
        return true;
      } else {
        error = result['message'] ?? 'Failed to delete';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminCollegeStaffProvider =
    ChangeNotifierProvider<AdminCollegeStaffProvider>(
        (ref) => AdminCollegeStaffProvider());
