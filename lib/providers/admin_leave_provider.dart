import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../services/admin_leave_service.dart';

class AdminLeaveProvider extends ChangeNotifier {
  List<dynamic> _leaves = [];
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

  List<dynamic> get leaves => _leaves;
  List<dynamic> get pendingLeaves =>
      _leaves.where((l) => (l['status'] ?? '').toString().toUpperCase() == 'PENDING').toList();

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
          await AdminLeaveService.getAll(page: page, size: size);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        _leaves = pageData.content;
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load leaves';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetch(page: currentPage, size: pageSize);

  Future<void> _refetchAfterMutation() async {
    await refresh();
    if (_leaves.isEmpty && currentPage > 0) {
      await fetch(page: currentPage - 1, size: pageSize);
    }
  }

  Future<bool> approveLeave(String adminId, String leaveId) async {
    try {
      final result =
          await AdminLeaveService.reviewLeave(adminId, leaveId, 'APPROVED');
      if (result['success'] == true) {
        await _refetchAfterMutation();
        return true;
      } else {
        error = result['message'] ?? 'Failed to approve';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> rejectLeave(String adminId, String leaveId) async {
    try {
      final result =
          await AdminLeaveService.reviewLeave(adminId, leaveId, 'REJECTED');
      if (result['success'] == true) {
        await _refetchAfterMutation();
        return true;
      } else {
        error = result['message'] ?? 'Failed to reject';
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

final adminLeaveProvider =
    ChangeNotifierProvider<AdminLeaveProvider>((ref) => AdminLeaveProvider());
