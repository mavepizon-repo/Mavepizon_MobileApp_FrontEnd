import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/staff_profile_service.dart';

class StaffProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool isLoading = false;
  String? error;

  Map<String, dynamic>? get profile => _profile;
  String get name => _profile?['name']?.toString() ?? '';
  String get email => _profile?['email']?.toString() ?? '';
  String get role => _profile?['role']?.toString() ?? '';
  String get category => _profile?['category']?.toString() ?? '';
  String get branch => _profile?['branch']?.toString() ?? '';
  String get score => _profile?['score']?.toString() ?? '0';
  String get profilePhoto =>
      (_profile?['profilePhoto'] ?? _profile?['profile'])?.toString() ?? '';
  int get totalTasks => _profile?['assignedTasks'] ?? 0;
  int get completedTasks => _profile?['completedTasks'] ?? 0;
  int get pendingTasks => _profile?['pendingTasks'] ?? 0;

  /// Custom per-staff shift start/end times (matching backend `shiftStartTime`
  /// / `shiftEndTime` fields). Fall back to 09:00 / 18:00 when not set.
  String get shiftStartTime => (_profile?['shiftStartTime']?.toString() ?? '')
      .isNotEmpty
      ? _profile!['shiftStartTime'].toString()
      : '09:00';
  String get shiftEndTime => (_profile?['shiftEndTime']?.toString() ?? '')
      .isNotEmpty
      ? _profile!['shiftEndTime'].toString()
      : '18:00';

  Future<void> fetch(String staffId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StaffProfileService.getProfile(staffId);
      if (result['success'] == true) {
        _profile = Map<String, dynamic>.from(result['data'] ?? {});
      } else {
        error = result['message'] ?? 'Failed to load profile';
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

final staffProfileProvider =
    ChangeNotifierProvider<StaffProfileProvider>((ref) => StaffProfileProvider());
