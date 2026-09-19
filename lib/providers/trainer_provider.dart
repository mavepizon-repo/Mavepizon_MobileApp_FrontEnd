import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trainer_service.dart';

class TrainerProvider extends ChangeNotifier {
  List<dynamic> _batches = [];
  dynamic _selectedBatch;
  Map<String, dynamic>? _dashboard;
  bool isLoading = false;
  String? error;

  List<dynamic> get batches => _batches;
  dynamic get selectedBatch => _selectedBatch;
  Map<String, dynamic>? get dashboard => _dashboard;

  Future<void> fetchBatches(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TrainerService.getBatches(staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _batches = data;
        } else {
          _batches = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load batches';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBatchStudents(String staffId, String batchId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await TrainerService.getBatchStudents(staffId, batchId);
      if (result['success'] == true) {
        _selectedBatch = result['data'];
      } else {
        error = result['message'] ?? 'Failed to load batch students';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboard(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TrainerService.getDashboard(staffId);
      if (result['success'] == true) {
        _dashboard = Map<String, dynamic>.from(result['data'] ?? {});
      } else {
        error = result['message'] ?? 'Failed to load dashboard';
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

final trainerProvider =
    ChangeNotifierProvider<TrainerProvider>((ref) => TrainerProvider());
