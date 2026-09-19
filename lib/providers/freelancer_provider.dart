import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await FreelancerTaskService.getAll();
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

  Future<bool> create(Map<String, dynamic> data) async {
    final result = await FreelancerTaskService.create(data);
    if (result['success'] == true) {
      await fetchAll();
      return true;
    }
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await FreelancerTaskService.update(id, data);
    if (result['success'] == true) {
      await fetchAll();
      return true;
    }
    return false;
  }

  Future<bool> delete(String id) async {
    final result = await FreelancerTaskService.delete(id);
    if (result['success'] == true) {
      await fetchAll();
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
