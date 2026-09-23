import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pagination_data.dart';
import '../services/telecaller_service.dart';

class TelecallerProvider extends ChangeNotifier {
  List<dynamic> _enquiries = [];
  List<dynamic> _followups = [];
  dynamic _selectedEnquiry;
  bool isLoading = false;
  String? error;

  List<dynamic> get enquiries => _enquiries;
  List<dynamic> get followups => _followups;
  dynamic get selectedEnquiry => _selectedEnquiry;

  Future<void> fetchEnquiries(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TelecallerService.getEnquiries(staffId);
      if (result['success'] == true) {
        _enquiries = PaginationData.parse(result['data']).content;
      } else {
        error = result['message'] ?? 'Failed to load enquiries';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> createEnquiry(
      String staffId, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TelecallerService.createEnquiry(staffId, data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to create enquiry';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchTodayFollowups(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TelecallerService.getTodayFollowups(staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _followups = data;
        } else {
          _followups = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load followups';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCustomFollowups(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TelecallerService.getCustomFollowups(staffId);
      if (result['success'] == true) {
        _followups = PaginationData.parse(result['data']).content;
      } else {
        error = result['message'] ?? 'Failed to load custom followups';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addFollowup(
      String staffId, String enquiryId, Map<String, dynamic> data) async {
    try {
      final result =
          await TelecallerService.addFollowup(staffId, enquiryId, data);
      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to add followup';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<void> filterByCollege(String staffId, String college) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await TelecallerService.filterByCollege(staffId, college);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _enquiries = data;
        } else {
          _enquiries = [];
        }
      } else {
        error = result['message'] ?? 'No results';
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

final telecallerProvider =
    ChangeNotifierProvider<TelecallerProvider>((ref) => TelecallerProvider());
