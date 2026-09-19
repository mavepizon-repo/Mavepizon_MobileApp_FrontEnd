import '../core/network/api_client.dart';

class StudentPaymentService {
  StudentPaymentService._();

  // POST /api/payment/razorpay/create-order
  static Future<Map<String, dynamic>> createRazorpayOrder(
      int registrationId) {
    return ApiClient.post('/api/payment/razorpay/create-order', {
      'registrationId': registrationId,
    });
  }

  // POST /api/payment/razorpay/verify
  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required int registrationId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) {
    return ApiClient.post('/api/payment/razorpay/verify', {
      'registrationId': registrationId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    });
  }

  // GET /api/payment/razorpay/{id}
  static Future<Map<String, dynamic>> getPaymentById(String id) {
    return ApiClient.get('/api/payment/razorpay/$id');
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  static Future<Map<String, dynamic>> getPaymentsByRegistration(
      String registrationId) {
    return ApiClient.get(
        '/api/payment/razorpay/registration/$registrationId');
  }
}
