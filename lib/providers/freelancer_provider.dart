import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/freelancer_task_model.dart';
import '../services/freelancer_service.dart';
import '../services/freelancer_task_service.dart';
import '../services/task_submission_service.dart';

class FreelancerTasksProvider extends ChangeNotifier {
  List<FreelancerTaskModel> tasks = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchMyTasks() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await FreelancerService.getMyTasks();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          tasks = data.map((e) => FreelancerTaskModel.fromJson(e)).toList();
        } else {
          tasks = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load tasks';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }
}

class AdminFreelancerTasksProvider extends ChangeNotifier {
  List<FreelancerTaskModel> tasks = [];
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

  Future<void> fetchAll({int page = 0, int size = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await FreelancerTaskService.getAll(page: page, size: size);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        tasks = pageData
            .map<FreelancerTaskModel>((e) => FreelancerTaskModel.fromJson(e))
            .toList();
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load tasks';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchAll(page: currentPage, size: pageSize);

  Future<bool> create(Map<String, dynamic> data) async {
    final result = await FreelancerTaskService.create(data);
    if (result['success'] == true) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await FreelancerTaskService.update(id, data);
    if (result['success'] == true) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> delete(String id) async {
    final result = await FreelancerTaskService.delete(id);
    if (result['success'] == true) {
      await refresh();
      if (tasks.isEmpty && currentPage > 0) {
        await fetchAll(page: currentPage - 1, size: pageSize);
      }
      return true;
    }
    return false;
  }
}

class TaskSubmissionProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<Map<String, dynamic>> submit(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    final result = await TaskSubmissionService.create(data);
    isLoading = false;
    if (result['success'] != true) {
      error = result['message'] ?? 'Failed to submit';
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    final result = await TaskSubmissionService.update(id, data);
    isLoading = false;
    if (result['success'] != true) {
      error = result['message'] ?? 'Failed to update submission';
    }
    notifyListeners();
    return result;
  }
}

final freelancerTasksProvider =
    ChangeNotifierProvider<FreelancerTasksProvider>(
        (ref) => FreelancerTasksProvider());
final adminFreelancerTasksProvider =
    ChangeNotifierProvider<AdminFreelancerTasksProvider>(
        (ref) => AdminFreelancerTasksProvider());
final taskSubmissionProvider =
    ChangeNotifierProvider<TaskSubmissionProvider>(
        (ref) => TaskSubmissionProvider());
