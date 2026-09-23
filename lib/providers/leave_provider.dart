import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/leave_service.dart';

class LeaveProvider extends ChangeNotifier {
  List<dynamic> _staffLeaves = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get staffLeaves => _staffLeaves;
  List<dynamic> get pendingLeaves =>
      _staffLeaves.where((l) => (l['status'] ?? 'PENDING') == 'PENDING').toList();

  Future<void> fetchStaffLeaves() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await LeaveService.getAllStaffLeaves();
    if (result['success'] == true) {
      final data = result['data'];
      List<dynamic>? parsed;
      if (data is List) {
        parsed = data;
      } else if (data is Map) {
        for (final key in ['content', 'leaves', 'records', 'data']) {
          final v = data[key];
          if (v is List) {
            parsed = v;
            break;
          }
        }
      }
      _staffLeaves = parsed ?? [];
    } else {
      error = result['message'];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> approveLeave(String leaveId) async {
    final result = await LeaveService.reviewStaffLeave(leaveId, 'APPROVED');
    if (result['success'] == true) {
      await fetchStaffLeaves();
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> rejectLeave(String leaveId) async {
    final result = await LeaveService.reviewStaffLeave(leaveId, 'REJECTED');
    if (result['success'] == true) {
      await fetchStaffLeaves();
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> applyOwnLeave(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    final result = await LeaveService.applyTeamLeadLeave(data);
    isLoading = false;
    if (result['success'] == true) {
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }
}

final leaveProvider = ChangeNotifierProvider<LeaveProvider>((ref) => LeaveProvider());
