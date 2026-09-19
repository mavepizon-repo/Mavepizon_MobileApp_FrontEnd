import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_lead_model.dart';
import '../services/admin_team_lead_service.dart';

class AdminTeamLeadProvider extends ChangeNotifier {
  List<TeamLeadModel> _list = [];
  TeamLeadModel? _selected;
  bool isLoading = false;
  String? error;

  List<TeamLeadModel> get list => _list;
  TeamLeadModel? get selected => _selected;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminTeamLeadService.getAll();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _list = data.map((e) => TeamLeadModel.fromJson(e)).toList();
        } else {
          _list = [];
        }
      } else {
        error = result['message'] ?? 'Failed to load team leads';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminTeamLeadService.getById(id);
      if (result['success'] == true) {
        _selected = TeamLeadModel.fromJson(result['data']);
      } else {
        error = result['message'] ?? 'Failed to load team lead';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminTeamLeadService.create(data);
      if (result['success'] == true) {
        isLoading = false;
        notifyListeners();
        await fetch();
        return true;
      } else {
        error = result['message'] ?? 'Failed to create';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminTeamLeadService.update(id, data);
      if (result['success'] == true) {
        return true;
      } else {
        error = result['message'] ?? 'Failed to update';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleStatus(String id, bool active) async {
    try {
      final result = await AdminTeamLeadService.toggleStatus(id, active);
      if (result['success'] == true) {
        await fetch();
        return true;
      } else {
        error = result['message'] ?? 'Failed to toggle status';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> delete(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminTeamLeadService.delete(id);
      if (result['success'] == true) {
        _list.removeWhere((t) => t.id.toString() == id);
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = result['message'] ?? 'Failed to delete';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminTeamLeadProvider =
    ChangeNotifierProvider<AdminTeamLeadProvider>((ref) => AdminTeamLeadProvider());
