import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_model.dart';
import '../services/staff_service.dart';

class StaffProvider extends ChangeNotifier {
  List<StaffModel> _list = [];
  StaffModel? selected;
  bool isLoading = false;
  String? error;
  String filterCategory = 'ALL';

  List<StaffModel> get allStaff => _list;

  List<StaffModel> get list {
    var result = _list;
    if (filterCategory != 'ALL') {
      result = result.where((s) => s.category == filterCategory).toList();
    }
    return result;
  }

  void setFilter(String category) {
    filterCategory = category;
    notifyListeners();
  }

  // ─── FETCH ALL STAFF ──────────────────────────────────────────
  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.getAll();

    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        _list = data
            .map((j) => StaffModel.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _list = [];
      }
      error = null;
    } else {
      error = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── FETCH BY ID ──────────────────────────────────────────────
  Future<void> fetchById(String staffId) async {
    try {
      final found = _list.firstWhere((s) => s.id == staffId);
      selected = found;
      notifyListeners();
      return;
    } catch (_) {
      // Not found in the already-loaded local list — expected, fall
      // through to fetch it from the API below.
    }

    isLoading = true;
    error = null;
    notifyListeners();

    await fetch();

    try {
      selected = _list.firstWhere((s) => s.id == staffId);
    } catch (_) {
      error = 'Staff not found';
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── CREATE STAFF ─────────────────────────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.create(data);
    isLoading = false;

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── UPDATE STAFF ─────────────────────────────────────────────
  Future<bool> update(String staffId, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.update(staffId, data);
    isLoading = false;

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── CREATE STAFF WITH FILES ──────────────────────────────────
  Future<bool> createWithFiles(
    Map<String, dynamic> data, {
    ({Uint8List bytes, String name})? profile,
    ({Uint8List bytes, String name})? aadhaar,
    ({Uint8List bytes, String name})? resume,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.create(data);
    isLoading = false;

    if (result['success'] != true) {
      error = result['message'];
      notifyListeners();
      return false;
    }

    final staffId = result['data']?['staffId']?.toString() ?? '';
    if (staffId.isEmpty) {
      await fetch();
      return true;
    }

    if (profile != null || aadhaar != null || resume != null) {
      final uploadResult = await StaffService.uploadFiles(
        staffId,
        profile: profile,
        aadhaar: aadhaar,
        resume: resume,
      );
      if (uploadResult['success'] != true) {
        error = uploadResult['message'] ?? 'File upload failed';
        notifyListeners();
        return false;
      }
    }

    await fetch();
    return true;
  }

  // ─── UPDATE STAFF WITH FILES ──────────────────────────────────
  Future<bool> updateWithFiles(
    String staffId,
    Map<String, dynamic> data, {
    ({Uint8List bytes, String name})? profile,
    ({Uint8List bytes, String name})? aadhaar,
    ({Uint8List bytes, String name})? resume,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.update(staffId, data);
    isLoading = false;

    if (result['success'] != true) {
      error = result['message'];
      notifyListeners();
      return false;
    }

    if (profile != null || aadhaar != null || resume != null) {
      final uploadResult = await StaffService.uploadFiles(
        staffId,
        profile: profile,
        aadhaar: aadhaar,
        resume: resume,
      );
      if (uploadResult['success'] != true) {
        error = uploadResult['message'] ?? 'File upload failed';
        notifyListeners();
        return false;
      }
    }

    await fetch();
    return true;
  }

  // ─── TOGGLE STATUS ────────────────────────────────────────────
  // ✅ FIX: Uses copyWith() instead of manually reconstructing StaffModel.
  // Old code manually listed every field — if a new field is added to
  // StaffModel, the old approach would silently reset it to null.
  // copyWith() safely copies all existing values and only overrides status.
  Future<bool> toggleStatus(String staffId, String newStatus) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final bool active = newStatus == 'ACTIVE';
    final result = await StaffService.toggleStatus(staffId, active);
    isLoading = false;

    if (result['success'] == true) {
      // ✅ FIX: copyWith keeps all other fields intact
      _list = _list.map((s) {
        if (s.id == staffId) return s.copyWith(status: newStatus);
        return s;
      }).toList();

      if (selected?.id == staffId) {
        selected = selected!.copyWith(status: newStatus);
      }

      notifyListeners();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── DELETE STAFF ─────────────────────────────────────────────
  Future<bool> delete(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await StaffService.delete(staffId);
    isLoading = false;

    if (result['success'] == true) {
      _list.removeWhere((s) => s.id == staffId);
      if (selected?.id == staffId) selected = null;
      notifyListeners();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }
}

final staffProvider = ChangeNotifierProvider<StaffProvider>((ref) => StaffProvider());
