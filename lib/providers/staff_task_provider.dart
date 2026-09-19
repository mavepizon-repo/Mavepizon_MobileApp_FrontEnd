import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_task_service.dart';

class StaffTaskProvider extends ChangeNotifier {
  List<dynamic> _tasks = [];
  bool isLoading = false;
  String? error;
  String _lastStaffId = '';

  List<dynamic> get tasks => _tasks;
  List<dynamic> get completedTasks =>
      _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').toList();
  List<dynamic> get pendingTasks =>
      _tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() != 'COMPLETED').toList();

  Future<void> fetch(String staffId) async {
    _lastStaffId = staffId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StaffTaskService.getTasks(staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _tasks = data;
        } else {
          _tasks = [];
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

  Future<bool> updateProgress(String taskId, int progress) async {
    try {
      final result =
          await StaffTaskService.updateProgress(taskId, {'progress': progress});
      if (result['success'] == true) {
        await fetch(_lastStaffId);
        return true;
      } else {
        error = result['message'] ?? 'Failed to update progress';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> submitTask(String taskId) async {
    try {
      final result = await StaffTaskService.submitTask(taskId);
      if (result['success'] == true) {
        await fetch(_lastStaffId);
        return true;
      } else {
        error = result['message'] ?? 'Failed to submit';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final staffTaskProvider =
    ChangeNotifierProvider<StaffTaskProvider>((ref) => StaffTaskProvider());
