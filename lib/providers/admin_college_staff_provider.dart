import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_staff_model.dart';
import '../services/admin_college_staff_service.dart';

class AdminCollegeStaffProvider extends ChangeNotifier {
  List<CollegeStaffModel> _list = [];
  CollegeStaffModel? _selected;
  bool isLoading = false;
  String? error;

  List<CollegeStaffModel> get list => _list;
  CollegeStaffModel? get selected => _selected;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _list = data.map((e) => CollegeStaffModel.fromJson(e)).toList();
        } else {
          _list = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load college staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.getById(id);
      if (result['success'] == true) {
        _selected = CollegeStaffModel.fromJson(result['data']);
      } else {
        error = result['message'] ?? 'Failed to load college staff';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.create(data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        await fetch();
        return true;
      } else {
        error = result['message'] ?? 'Failed to create';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.update(id, data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        await fetch();
        return true;
      } else {
        error = result['message'] ?? 'Failed to update';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> delete(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminCollegeStaffService.delete(id);
      if (result['success'] == true) {
        await fetch();
        return true;
      } else {
        error = result['message'] ?? 'Failed to delete';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminCollegeStaffProvider =
    ChangeNotifierProvider<AdminCollegeStaffProvider>(
        (ref) => AdminCollegeStaffProvider());
