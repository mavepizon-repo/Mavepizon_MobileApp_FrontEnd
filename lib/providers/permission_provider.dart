import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';

class PermissionProvider extends ChangeNotifier {
  List<dynamic> _permissions = [];
  bool isLoading = false;
  String? error;

  List<dynamic> get permissions => _permissions;
  List<dynamic> get pendingPermissions =>
      _permissions.where((p) => (p['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING').toList();

  Future<void> fetchBranchPermissions() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await PermissionService.getBranchPermissions();
    debugPrint('[PermissionProvider] getBranchPermissions result: $result');

    if (result['success'] == true) {
      final d = result['data'];
      List<dynamic>? parsed;
      if (d is List) {
        parsed = d;
      } else if (d is Map) {
        for (final key in ['data', 'permissions', 'content', 'records']) {
          final v = d[key];
          if (v is List) { parsed = v; break; }
        }
      }
      if (parsed != null) {
        _permissions = parsed
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .cast<Map<String, dynamic>>()
            .toList();
        debugPrint('[PermissionProvider] ${_permissions.length} permissions parsed');
      } else {
        _permissions = [];
        debugPrint('[PermissionProvider] unexpected data format: ${d.runtimeType}');
      }
    } else {
      error = result['message'];
      debugPrint('[PermissionProvider] fetch error: $error');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> approvePermission(String permissionId) async {
    final result = await PermissionService.approvePermission(permissionId);
    if (result['success'] == true) {
      await fetchBranchPermissions();
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> rejectPermission(String permissionId, String remarks) async {
    final result =
        await PermissionService.rejectPermission(permissionId, remarks);
    if (result['success'] == true) {
      await fetchBranchPermissions();
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> applyOwnPermission(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();

    final result = await PermissionService.applyTeamLeadPermission(data);
    isLoading = false;
    if (result['success'] == true) {
      return true;
    }
    error = result['message'];
    notifyListeners();
    return false;
  }
}

final permissionProvider =
    ChangeNotifierProvider<PermissionProvider>((ref) => PermissionProvider());
