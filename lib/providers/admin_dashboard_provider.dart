import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../services/admin_dashboard_service.dart';
import '../services/freelancer_service.dart';
import '../services/freelancer_task_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  int _freelancerCount = 0;
  int _freelancerTaskCount = 0;
  bool isLoading = false;
  String? error;

  Map<String, dynamic> get stats => _stats;
  int get freelancerCount => _freelancerCount;
  int get freelancerTaskCount => _freelancerTaskCount;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminDashboardService.getStats();
      if (result['success'] == true) {
        _stats = Map<String, dynamic>.from(result['data'] ?? {});
      } else {
        error = result['message'] ?? 'Failed to load dashboard';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    await _fetchFreelancerStats();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchFreelancerStats() async {
    try {
      final fl = await FreelancerService.getAll();
      if (fl['success'] == true) {
        _freelancerCount = PaginationData.parse(fl['data']).totalElements;
      }

      final tasks = await FreelancerTaskService.getAll();
      if (tasks['success'] == true) {
        _freelancerTaskCount = PaginationData.parse(tasks['data']).totalElements;
      }
    } catch (e) {
      // Non-fatal; keep last known counts.
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminDashboardProvider =
    ChangeNotifierProvider<AdminDashboardProvider>((ref) => AdminDashboardProvider());
