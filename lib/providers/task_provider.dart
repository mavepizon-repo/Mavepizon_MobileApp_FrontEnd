import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  // ✅ Full unfiltered list
  List<TaskModel> _allList = [];

  bool isLoading = false;
  String? error;
  String filterStatus = 'ALL';

  List<TaskModel> get allTasks => _allList;

  // ✅ Filtered list for UI display
  List<TaskModel> get list {
    if (filterStatus == 'ALL') return _allList;
    return _allList.where((t) => t.status == filterStatus).toList();
  }

  // ✅ Always search the FULL list — used by detail/edit screens
  TaskModel? getById(String taskId) {
    try {
      return _allList.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  void setFilter(String s) {
    filterStatus = s;
    notifyListeners();
  }

  // ─── FETCH ALL TASKS ──────────────────────────────────────────
  Future<void> fetch({
    String? staffId,
    String? startDate,
    String? endDate,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    Map<String, dynamic> result;

    result = await TaskService.getAll(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );

    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        _allList = data
            .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _allList = [];
      }
      error = null;
    } else {
      error = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── ASSIGN TASK ──────────────────────────────────────────────
  Future<bool> assign(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await TaskService.assign(data);
    isLoading = false;

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── ASSIGN TASK TO GROUP ─────────────────────────────────────
  Future<bool> assignGroup(
      Map<String, dynamic> data, List<int> staffIds) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await TaskService.assignGroup(data, staffIds);
    isLoading = false;

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── ASSIGN ALL ───────────────────────────────────────────────
  Future<bool> assignAll(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await TaskService.assignAll(data);
    isLoading = false;

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── UPDATE TASK ──────────────────────────────────────────────
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await TaskService.update(id, data);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── DELETE TASK ──────────────────────────────────────────────
  Future<bool> delete(String id) async {
    final result = await TaskService.delete(id);
    if (result['success'] == true) {
      _allList.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── REVIEW TASK ──────────────────────────────────────────────
  Future<bool> reviewTask(String id, Map<String, dynamic> data) async {
    final result = await TaskService.reviewTask(id, data);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }
}

final taskProvider = ChangeNotifierProvider<TaskProvider>((ref) => TaskProvider());
