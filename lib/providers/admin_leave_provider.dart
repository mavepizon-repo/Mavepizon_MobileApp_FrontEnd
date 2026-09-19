import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_leave_service.dart';

class AdminLeaveProvider extends ChangeNotifier {
  List<dynamic> _leaves = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get leaves => _leaves;
  List<dynamic> get pendingLeaves =>
      _leaves.where((l) => (l['status'] ?? '').toString().toUpperCase() == 'PENDING').toList();

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminLeaveService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _leaves = data;
        } else {
          _leaves = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load leaves';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> approveLeave(String adminId, String leaveId) async {
    try {
      final result =
          await AdminLeaveService.reviewLeave(adminId, leaveId, 'APPROVED');
      if (result['success'] == true) {
        await fetch();
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
        await fetch();
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
