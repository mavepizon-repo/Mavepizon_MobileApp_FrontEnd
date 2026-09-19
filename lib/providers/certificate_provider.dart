import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';

class CertificateProvider extends ChangeNotifier {
  List<CertificateModel> list = [];
  bool isLoading = false;
  String? error;

  // ─── FETCH ALL PENDING CERTIFICATES ──────────────────────────
  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await CertificateService.getAll();
    if (result['success'] != true || result['data'] is! List) {
      // Fallback to pending if all endpoint fails
      final fallback = await CertificateService.getPending();
      if (fallback['success'] == true && fallback['data'] is List) {
        result['data'] = fallback['data'];
        result['success'] = true;
      }
    }
    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        list = data
            .map((j) => CertificateModel.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        list = [];
      }
      error = null;
    } else {
      error = result['message'];
      list = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── UPLOAD CERTIFICATE FILE ────────────────────────────────
  Future<bool> uploadCertificate(String id, File file) async {
    final result = await CertificateService.uploadCertificate(id, file);
    if (result['success'] == true) {
      await fetch();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────
  Future<bool> delete(String id) async {
    final result = await CertificateService.delete(id);
    if (result['success'] == true) {
      list.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } else {
      error = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ─── INITIATE BATCH ───────────────────────────────────────────
  // Backend only has POST /api/certificates/create/{registrationId},
  // so we loop over all paid registrations that don't already have a
  // certificate record and create them one by one.
  Future<bool> initiateBatch(String batchId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final regResult = await CertificateService.getAllRegistrations();
      if (regResult['success'] != true || regResult['data'] is! List) {
        error =
            regResult['message'] ?? 'Failed to load registrations';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final certResult = await CertificateService.getAll();
      final existingCodes = <String>{};
      if (certResult['success'] == true && certResult['data'] is List) {
        for (final c in certResult['data'] as List) {
          if (c is Map) {
            final code = c['studentCode']?.toString() ?? '';
            if (code.isNotEmpty) existingCodes.add(code);
          }
        }
      }

      int created = 0;
      for (final r in regResult['data'] as List) {
        if (r is! Map) continue;
        final map = Map<String, dynamic>.from(r);
        final pay = map['paymentStatus']?.toString().toUpperCase() ?? '';
        if (pay != 'PAID' && pay != 'SUCCESS' && pay != 'COMPLETED') {
          continue;
        }

        final student = map['student'] is Map
            ? Map<String, dynamic>.from(map['student'])
            : null;
        final code = student?['studentId']?.toString() ?? '';
        if (existingCodes.contains(code)) continue;

        final regId = map['id']?.toString();
        if (regId == null || regId.isEmpty) continue;

        final res = await CertificateService.create(regId);
        if (res['success'] == true) {
          created++;
          existingCodes.add(code);
        }
      }

      await fetch();
      return created > 0;
    } catch (e) {
      error = 'Failed to initiate batch';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── UPDATE STATUS ─────────────────────────────────────────────
  Future<bool> updateStatus(String id, String status) async {
    final result = await CertificateService.updateStatus(id, status);
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

final certificateProvider = ChangeNotifierProvider<CertificateProvider>((ref) => CertificateProvider());
