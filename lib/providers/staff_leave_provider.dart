import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_leave_service.dart';

class StaffLeaveProvider extends ChangeNotifier {
  List<dynamic> _leaves = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get leaves => _leaves;

  Future<bool> applyLeave(String staffId, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StaffLeaveService.applyLeave(staffId, data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to apply leave';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchHistory(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StaffLeaveService.getLeaveHistory(staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _leaves = data;
        } else {
          _leaves = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load leave history';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final staffLeaveProvider =
    ChangeNotifierProvider<StaffLeaveProvider>((ref) => StaffLeaveProvider());
