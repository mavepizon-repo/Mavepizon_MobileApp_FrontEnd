import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  List<CourseModel> list = [];
  bool isLoading = false;
  String? error;

  // ─── FETCH ALL COURSES ──────────────────────────────────────────
  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await CourseService.getAll();
    if (result['success'] == true) {
      // ✅ FIX: Guard against null / non-List response instead of blind cast.
      final data = result['data'];
      if (data is List) {
        list = data.map((j) => CourseModel.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        list = [];
      }
    } else {
      error = result['message'];
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── CREATE COURSE ─────────────────────────────────────────────
  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await CourseService.create(data);
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

  // ─── UPDATE COURSE ─────────────────────────────────────────────
  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await CourseService.update(id, data);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── DELETE COURSE ─────────────────────────────────────────────
  Future<bool> delete(String id) async {
    final result = await CourseService.delete(id);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }

  // ─── TOGGLE STATUS ─────────────────────────────────────────────
  Future<bool> toggleStatus(String id, String status) async {
    final result = await CourseService.toggleStatus(id, status);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      return false;
    }
  }
}

final courseProvider = ChangeNotifierProvider<CourseProvider>((ref) => CourseProvider());