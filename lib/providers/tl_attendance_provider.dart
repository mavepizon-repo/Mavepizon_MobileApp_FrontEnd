import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tl_attendance_service.dart';

class TlAttendanceProvider extends ChangeNotifier {
  List<dynamic> _history = [];
  Map<String, dynamic>? _lastCheck;
  bool isLoading = false;
  String? error;

  List<dynamic> get history => _history;
  Map<String, dynamic>? get lastCheck => _lastCheck;
  bool get isCheckedIn => _lastCheck != null && _lastCheck!['checkOutTime'] == null;

  Future<bool> checkIn(double lat, double lng) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TlAttendanceService.checkIn(lat, lng);
      if (result['success'] == true) {
        if (result['data'] is Map) {
          _lastCheck = Map<String, dynamic>.from(result['data']);
          _history.insert(0, Map<String, dynamic>.from(_lastCheck!));
        }
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Check-in failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> checkOut() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TlAttendanceService.checkOut();
      if (result['success'] == true) {
        if (result['data'] is Map) {
          _lastCheck = Map<String, dynamic>.from(result['data']);
        } else if (_lastCheck != null) {
          _lastCheck!['checkOutTime'] = result['data']?['checkOutTime'];
        }
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Check-out failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchHistory(String teamLeadId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await TlAttendanceService.getHistory(teamLeadId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final sorted = List<dynamic>.from(data)
            ..sort((a, b) => (b['attendanceDate']?.toString() ?? '')
                .compareTo(a['attendanceDate']?.toString() ?? ''));
          _history = sorted;
          if (sorted.isNotEmpty) {
            _lastCheck = Map<String, dynamic>.from(sorted.first);
          }
        }
      } else {
        error = result['message'] ?? 'Failed to load history';
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

final tlAttendanceProvider =
    ChangeNotifierProvider<TlAttendanceProvider>((ref) => TlAttendanceProvider());
