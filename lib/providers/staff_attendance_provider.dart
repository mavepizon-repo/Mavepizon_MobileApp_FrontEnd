import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_attendance_service.dart';

class StaffAttendanceProvider extends ChangeNotifier {
  List<dynamic> _history = [];
  Map<String, dynamic>? _lastCheck;
  bool _checkedIn = false;
  bool isLoading = false;
  String? error;

  List<dynamic> get history => _history;
  Map<String, dynamic>? get lastCheck => _lastCheck;

  /// Whether the staff has actually checked in *during this app session* by
  /// pressing the "Check In" button. It is never derived automatically from
  /// stored history, so a freshly logging-in staff is always shown a "Check In"
  /// button first. Only after a successful check-in click does the "Check Out"
  /// option appear (and it clears again after a successful check-out).
  bool get isCheckedIn => _checkedIn;

  Future<bool> checkIn(double lat, double lng) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await StaffAttendanceService.checkIn(lat, lng);
      if (result['success'] == true) {
        if (result['data'] is Map) {
          _lastCheck = Map<String, dynamic>.from(result['data']);
          _history.insert(0, Map<String, dynamic>.from(_lastCheck!));
          _checkedIn = true;
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
      final result = await StaffAttendanceService.checkOut();
      if (result['success'] == true) {
        if (result['data'] is Map) {
          _lastCheck = Map<String, dynamic>.from(result['data']);
        } else if (_lastCheck != null) {
          _lastCheck!['checkOutTime'] = result['data']?['checkOutTime'];
        }
        _checkedIn = false;
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

  Future<void> fetchHistory() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StaffAttendanceService.getHistory();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final sorted = List<dynamic>.from(data)
            ..sort((a, b) => (b['attendanceDate']?.toString() ?? '')
                .compareTo(a['attendanceDate']?.toString() ?? ''));
          _history = sorted;
          // Only refresh display data (In/Out times); never auto-mark the staff
          // as checked in from server history.
          _lastCheck = _todayRecord(sorted);
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

  /// Returns the attendance record for *today* only (most recent first), or
  /// null when the staff has no record for today. Used only for displaying the
  /// In/Out times; it does NOT change the check-in/check-out button state.
  Map<String, dynamic>? _todayRecord(List<dynamic> sorted) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    for (final r in sorted) {
      final date = (r['attendanceDate']?.toString() ?? '').split(' ').first;
      if (date == today) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final staffAttendanceProvider =
    ChangeNotifierProvider<StaffAttendanceProvider>((ref) => StaffAttendanceProvider());
