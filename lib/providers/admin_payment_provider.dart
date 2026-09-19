import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_payment_service.dart';

class AdminPaymentProvider extends ChangeNotifier {
  List<dynamic> _registrations = [];
  Map<String, dynamic>? _selectedPayment;
  bool isLoading = false;
  String? error;

  List<dynamic> get registrations => _registrations;
  Map<String, dynamic>? get selectedPayment => _selectedPayment;

  // GET /api/student-course/get-all
  // Every course registration carries paymentStatus + registrationStatus.
  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AdminPaymentService.getAllRegistrations();
      if (result['success'] == true) {
        final data = result['data'];
        _registrations = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load payments';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  Future<List<dynamic>> fetchPaymentsByRegistration(
      String registrationId) async {
    try {
      final result = await AdminPaymentService.getByRegistration(
          registrationId);
      if (result['success'] == true) {
        final data = result['data'];
        return data is List ? data : [];
      }
      error = result['message'] ?? 'Failed to load payments';
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return [];
  }

  // GET /api/payment/razorpay/{id}
  Future<Map<String, dynamic>?> fetchPaymentDetail(String id) async {
    try {
      final result = await AdminPaymentService.getById(id);
      if (result['success'] == true) {
        final data = result['data'];
        _selectedPayment =
            data is Map ? Map<String, dynamic>.from(data) : null;
        notifyListeners();
        return _selectedPayment;
      }
      error = result['message'] ?? 'Failed to load payment detail';
    } catch (e) {
      error = 'Error: $e';
    }
    notifyListeners();
    return null;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}

final adminPaymentProvider =
    ChangeNotifierProvider<AdminPaymentProvider>((ref) => AdminPaymentProvider());
