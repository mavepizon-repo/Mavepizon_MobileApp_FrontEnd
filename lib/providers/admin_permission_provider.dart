import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_permission_service.dart';

class AdminPermissionProvider extends ChangeNotifier {
  List<dynamic> _permissions = [];
  List<dynamic> _allPermissions = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get permissions => _permissions;
  List<dynamic> get allPermissions => _allPermissions;
  List<dynamic> get pendingPermissions =>
      _allPermissions.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').toList();

  void _mergeIntoAll(List<dynamic> pending) {
    for (final item in pending) {
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) {
        final idx = _allPermissions.indexWhere((p) => p['id']?.toString() == id);
        if (idx >= 0) {
          _allPermissions[idx] = item;
        } else {
          _allPermissions.add(item);
        }
      }
    }
  }

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminPermissionService.getPending();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _permissions = data;
          _mergeIntoAll(data);
        } else {
          _permissions = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load permissions';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> approve(String permissionId) async {
    try {
      final result = await AdminPermissionService.approve(permissionId);
      if (result['success'] == true) {
        final idx = _allPermissions.indexWhere((p) => p['id']?.toString() == permissionId);
        if (idx >= 0) {
          _allPermissions[idx]['status'] = 'APPROVED';
        }
        _permissions.removeWhere((p) => p['id']?.toString() == permissionId);
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

  Future<bool> reject(String permissionId, String remarks) async {
    try {
      final result = await AdminPermissionService.reject(permissionId, remarks);
      if (result['success'] == true) {
        final idx = _allPermissions.indexWhere((p) => p['id']?.toString() == permissionId);
        if (idx >= 0) {
          _allPermissions[idx]['status'] = 'REJECTED';
          _allPermissions[idx]['remarks'] = remarks;
        }
        _permissions.removeWhere((p) => p['id']?.toString() == permissionId);
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

final adminPermissionProvider =
    ChangeNotifierProvider<AdminPermissionProvider>((ref) => AdminPermissionProvider());
