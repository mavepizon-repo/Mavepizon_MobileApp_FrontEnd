import '../core/network/api_client.dart';

class AdminPaymentService {
  AdminPaymentService._();

  // GET /api/student-course/get-all
  // All course registrations carry paymentStatus + registrationStatus.
  static Future<Map<String, dynamic>> getAllRegistrations() {
    return ApiClient.get('/api/student-course/get-all');
  }

  // GET /api/payment/razorpay/registration/{registrationId}
  static Future<Map<String, dynamic>> getByRegistration(
      String registrationId) {
    return ApiClient.get(
        '/api/payment/razorpay/registration/$registrationId');
  }

  // GET /api/payment/razorpay/{id}
  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/payment/razorpay/$id');
  }
}

