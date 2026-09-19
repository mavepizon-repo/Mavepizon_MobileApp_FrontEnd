import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class CertificateService {
  CertificateService._();

  static Future<Map<String, dynamic>> getAll() async {
    return ApiClient.get('/api/certificates/all');
  }

  // ─── DESIGNER CERTIFICATE CREATION (course registrations) ──────
  // These endpoints are open to OFFICE_STAFF (designer) roles in the
  // backend security config, so no backend change is required.

  // Paid students who are eligible for a certificate.
  static Future<Map<String, dynamic>> getCertificateEligible() async {
    return ApiClient.get('/api/student-course/certificate-eligible');
  }

  // All course registrations (fallback data source).
  static Future<Map<String, dynamic>> getAllRegistrations() async {
    return ApiClient.get('/api/student-course/get-all');
  }

  // Single registration by id (for refreshing a specific record).
  static Future<Map<String, dynamic>> getRegistration(String id) async {
    return ApiClient.get('/api/student-course/get/$id');
  }

  static Future<Map<String, dynamic>> getPending() async {
    return ApiClient.get('/api/certificates/pending');
  }

  static Future<Map<String, dynamic>> getByBatch(String batchId) async {
    return ApiClient.get('/api/certificates/course/$batchId');
  }

  static Future<Map<String, dynamic>> getByStudent(String studentId) async {
    return ApiClient.get('/api/certificates/student/$studentId');
  }

  static Future<Map<String, dynamic>> create(String registrationId) async {
    return ApiClient.post('/api/certificates/create/$registrationId', {});
  }

  static Future<Map<String, dynamic>> uploadCertificate(
      String id, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/certificates/$id/upload'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final token = await StorageHelper.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await streamedResponse.stream.bytesToString();

    try {
      final decoded = jsonDecode(responseBody);
      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        return {
          'success': true,
          'data': decoded,
          'status': streamedResponse.statusCode
        };
      }
      return {
        'success': false,
        'message': decoded is Map
            ? (decoded['message'] ?? decoded['error'] ?? 'Upload failed')
            : 'Upload failed',
        'status': streamedResponse.statusCode,
        'data': decoded,
      };
    } catch (_) {
      return {
        'success': false,
        'message': responseBody.isEmpty ? 'Upload failed' : responseBody,
        'status': streamedResponse.statusCode,
        'data': responseBody,
      };
    }
  }

  static Future<Map<String, dynamic>> updateStatus(
      String id, String status) async {
    return ApiClient.put('/api/certificates/status/$id?status=$status', {});
  }

  static Future<Map<String, dynamic>> delete(String id) async {
    return ApiClient.delete('/api/certificates/$id');
  }
}