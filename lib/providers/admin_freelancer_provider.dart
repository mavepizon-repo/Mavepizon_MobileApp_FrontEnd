import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/freelancer_model.dart';
import '../services/freelancer_service.dart';

class AdminFreelancerProvider extends ChangeNotifier {
  List<FreelancerModel> list = [];
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await FreelancerService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          list = data.map((e) => FreelancerModel.fromJson(e)).toList();
        } else {
          list = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load freelancers';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    final result = await FreelancerService.create(data);
    if (result['success'] == true) {
      await fetch();
      return true;
    }
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await FreelancerService.update(id, data);
    if (result['success'] == true) {
      await fetch();
      return true;
    }
    return false;
  }

  Future<bool> delete(String id) async {
    final result = await FreelancerService.delete(id);
    if (result['success'] == true) {
      await fetch();
      return true;
    }
    return false;
  }

  Future<FreelancerModel?> getById(String id) async {
    final result = await FreelancerService.getById(id);
    if (result['success'] == true && result['data'] is Map) {
      return FreelancerModel.fromJson(result['data']);
    }
    return null;
  }
}

final adminFreelancerProvider =
    ChangeNotifierProvider<AdminFreelancerProvider>(
        (ref) => AdminFreelancerProvider());
