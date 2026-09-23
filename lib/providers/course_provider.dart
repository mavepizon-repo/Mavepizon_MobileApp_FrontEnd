import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  List<CourseModel> list = [];
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

  PaginationData get pagination => PaginationData(
        page: currentPage,
        totalPages: totalPages,
        totalElements: totalElements,
        size: pageSize,
      );

  // ─── FETCH ALL COURSES ──────────────────────────────────────────
  Future<void> fetch({int page = 0, int size = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await CourseService.getAll(page: page, size: size);
    if (result['success'] == true) {
      // Backend returns a Spring Page: { content: [...], totalElements: ... }
      final pageData = PaginationData.parse(result['data']);
      list = pageData
          .map<CourseModel>((j) => CourseModel.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      currentPage = pageData.page;
      totalPages = pageData.totalPages;
      totalElements = pageData.totalElements;
      if (pageData.size > 0) pageSize = pageData.size;
    } else {
      error = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetch(page: currentPage, size: pageSize);

  // ─── CREATE COURSE ─────────────────────────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await CourseService.create(data);
    isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      await refresh();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── UPDATE COURSE ─────────────────────────────────────────────
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await CourseService.update(id, data);
    if (result['success'] == true) {
      await refresh();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── DELETE COURSE ─────────────────────────────────────────────
  Future<bool> delete(String id) async {
    final result = await CourseService.delete(id);
    if (result['success'] == true) {
      await refresh();
      if (list.isEmpty && currentPage > 0) {
        await fetch(page: currentPage - 1, size: pageSize);
      }
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── TOGGLE STATUS ─────────────────────────────────────────────
  Future<bool> toggleStatus(String id, String status) async {
    final result = await CourseService.toggleStatus(id, status);
    if (result['success'] == true) {
      await refresh();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }
}

final courseProvider = ChangeNotifierProvider<CourseProvider>((ref) => CourseProvider());