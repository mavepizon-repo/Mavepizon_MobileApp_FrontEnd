import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/staff_model.dart';
import '../services/admin_staff_service.dart';

class AdminStaffProvider extends ChangeNotifier {
  List<StaffModel> _list = [];
  StaffModel? _selected;
  List<StaffModel> _pendingApprovals = [];
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

  List<StaffModel> get list => _list;
  StaffModel? get selected => _selected;
  List<StaffModel> get pendingApprovals => _pendingApprovals;
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
      final result = await AdminStaffService.getAll(page: page, size: size);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        _list = pageData
            .map<StaffModel>((e) => StaffModel.fromJson(e))
            .toList();
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetch(page: currentPage, size: pageSize);

  Future<void> fetchById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminStaffService.getById(id);
      if (result['success'] == true) {
        _selected = StaffModel.fromJson(result['data']);
      } else {
        error = result['message'] ?? 'Failed to load staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPendingApprovals() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminStaffService.getPendingApprovals();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _pendingApprovals =
              data.map((e) => StaffModel.fromJson(e)).toList();
        } else {
          _pendingApprovals = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load pending approvals';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> approveStaff(String staffId) async {
    try {
      final result = await AdminStaffService.approveStaff(staffId);
      if (result['success'] == true) {
        await fetchPendingApprovals();
        notifyListeners();
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

  Future<bool> delete(String id) async {
    try {
      final result = await AdminStaffService.delete(id);
      if (result['success'] == true) {
        await refresh();
        if (_list.isEmpty && currentPage > 0) {
          await fetch(page: currentPage - 1, size: pageSize);
        }
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to delete staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  /// Soft-delete fallback used when the hard delete fails on a foreign-key
  /// constraint (the backend cascade only clears tasks/permissions/leaves).
  Future<bool> deactivate(String id) async {
    try {
      final result = await AdminStaffService.setStatus(id, false);
      if (result['success'] == true) {
        await refresh();
        if (_list.isEmpty && currentPage > 0) {
          await fetch(page: currentPage - 1, size: pageSize);
        }
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to deactivate staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      final result = await AdminStaffService.update(id, data);
      if (result['success'] == true) {
        return true;
      } else {
        error = result['message'] ?? 'Failed to update staff';
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

final adminStaffProvider =
    ChangeNotifierProvider<AdminStaffProvider>((ref) => AdminStaffProvider());
