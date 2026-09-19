import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/internship_model.dart';
import '../services/internship_service.dart';

class InternshipProvider extends ChangeNotifier {
  List<InternshipModel> list = [];
  bool isLoading = false;
  String? error;

  // ─── FETCH ALL INTERNSHIPS ──────────────────────────────────────
  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await InternshipService.getAll();
    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        list = data
            .map((j) => InternshipModel.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        list = [];
      }
    } else {
      error = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── CREATE INTERNSHIP ─────────────────────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await InternshipService.create(data);
    isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── UPDATE INTERNSHIP ─────────────────────────────────────────
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await InternshipService.update(id, data);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── DELETE INTERNSHIP ─────────────────────────────────────────
  Future<bool> delete(String id) async {
    final result = await InternshipService.delete(id);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── TOGGLE STATUS ─────────────────────────────────────────────
  // PATCH /api/internship/{id}/status?status=ACTIVE|INACTIVE|CLOSED
  Future<bool> toggleStatus(String id, String status) async {
    final result = await InternshipService.toggleStatus(id, status);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }
}

final internshipProvider = ChangeNotifierProvider<InternshipProvider>((ref) => InternshipProvider());
