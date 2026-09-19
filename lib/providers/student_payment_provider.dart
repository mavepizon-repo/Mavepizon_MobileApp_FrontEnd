import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_payment_service.dart';

class StudentPaymentProvider extends ChangeNotifier {
  List<dynamic> _payments = [];
  Map<String, dynamic>? _selectedPayment;
  Map<String, dynamic>? _lastOrder;
  bool isLoading = false;
  String? error;

  List<dynamic> get payments => _payments;
  Map<String, dynamic>? get selectedPayment => _selectedPayment;
  Map<String, dynamic>? get lastOrder => _lastOrder;

  // POST /api/payment/razorpay/create-order
  Future<Map<String, dynamic>?> createRazorpayOrder(int registrationId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result =
          await StudentPaymentService.createRazorpayOrder(registrationId);
      if (result['success'] == true) {
        _lastOrder = Map<String, dynamic>.from(result['data'] ?? {});
        isLoading = false;
        notifyListeners();
        return _lastOrder;
      } else {
        error = result['message'] ?? 'Failed to create order';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return null;
  }

  // POST /api/payment/razorpay/verify
  Future<Map<String, dynamic>?> verifyPayment({
    required int registrationId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentPaymentService.verifyRazorpayPayment(
        registrationId: registrationId,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        isLoading = false;
        notifyListeners();
        return data;
      } else {
        error = result['status'] != null
            ? 'HTTP ${result['status']}: ${result['message'] ?? 'Payment verification failed'}'
            : result['message'] ?? 'Payment verification failed';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
    return null;
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  Future<void> fetchPaymentsByRegistration(String registrationId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentPaymentService.getPaymentsByRegistration(
          registrationId);
      if (result['success'] == true) {
        final data = result['data'];
        _payments = data is List ? data : [];
      } else {
        error = result['message'] ?? 'Failed to load payments';
      }
    } catch (e) {
      error = 'Error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  // GET /api/payment/razorpay/{id}
  Future<void> fetchPaymentDetail(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await StudentPaymentService.getPaymentById(id);
      if (result['success'] == true) {
        final data = result['data'];
        _selectedPayment =
            data is Map ? Map<String, dynamic>.from(data) : null;
      } else {
        error = result['message'] ?? 'Failed to load payment detail';
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

final studentPaymentProvider =
    ChangeNotifierProvider<StudentPaymentProvider>((ref) => StudentPaymentProvider());
