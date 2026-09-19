import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_permission_service.dart';

class StaffPermissionProvider extends ChangeNotifier {
  List<dynamic> _permissions = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get permissions => _permissions;

  Future<bool> applyPermission(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await StaffPermissionService.applyPermission(data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to apply permission';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchHistory() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await StaffPermissionService.getPermissionHistory();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _permissions = data;
        } else {
          _permissions = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load permission history';
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

final staffPermissionProvider =
    ChangeNotifierProvider<StaffPermissionProvider>((ref) => StaffPermissionProvider());
