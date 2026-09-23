import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../models/freelancer_model.dart';
import '../services/freelancer_service.dart';

class AdminFreelancerProvider extends ChangeNotifier {
  List<FreelancerModel> list = [];
  bool isLoading = false;
  String? error;

  int currentPage = 0;
  int totalPages = 1;
  int totalElements = 0;
  int pageSize = 20;

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
      final result = await FreelancerService.getAll(page: page, size: size);
      if (result['success'] == true) {
        final pageData = PaginationData.parse(result['data']);
        list = pageData
            .map<FreelancerModel>((e) => FreelancerModel.fromJson(e))
            .toList();
        currentPage = pageData.page;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
        if (pageData.size > 0) pageSize = pageData.size;
      } else {
        error = result['message'] ?? 'Failed to load freelancers';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetch(page: currentPage, size: pageSize);

  Future<bool> create(Map<String, dynamic> data) async {
    final result = await FreelancerService.create(data);
    if (result['success'] == true) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final result = await FreelancerService.update(id, data);
    if (result['success'] == true) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> delete(String id) async {
    final result = await FreelancerService.delete(id);
    if (result['success'] == true) {
      await refresh();
      if (list.isEmpty && currentPage > 0) {
        await fetch(page: currentPage - 1, size: pageSize);
      }
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
