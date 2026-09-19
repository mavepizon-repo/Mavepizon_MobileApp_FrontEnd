import 'dart:io';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';
import 'package:dio/dio.dart';

class TrainerService {
  TrainerService._();

  static Future<Map<String, dynamic>> getBatches(String staffId) {
    return ApiClient.get('/api/trainer/$staffId/batches');
  }

  static Future<Map<String, dynamic>> getOnlineBatches(String staffId) {
    return ApiClient.get('/api/trainer/$staffId/online-batches');
  }

  static Future<Map<String, dynamic>> getOfflineBatches(String staffId) {
    return ApiClient.get('/api/trainer/$staffId/offline-batches');
  }

  static Future<Map<String, dynamic>> markAttendance(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.post('/api/trainer/$staffId/attendance', data);
  }

  static Future<Map<String, dynamic>> uploadMaterial(
    String staffId,
    String courseId,
    String title,
    File file,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ));
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      final formData = FormData.fromMap({
        'title': title,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('\\').last.split('/').last,
        ),
      });
      final res = await dio.post('/api/trainer/$staffId/courses/$courseId/material', data: formData);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {'success': false, 'message': 'Upload failed (${res.statusCode})', 'data': res.data, 'status': res.statusCode};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ?? e.message
          : e.message;
      return {'success': false, 'message': msg ?? 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateZoomLink(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.put('/api/trainer/$staffId/zoom-link', data);
  }

  static Future<Map<String, dynamic>> confirmFee(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.post('/api/trainer/$staffId/fee-confirmation', data);
  }

  static Future<Map<String, dynamic>> getDashboard(String staffId) {
    return ApiClient.get('/api/trainer/$staffId/dashboard');
  }

  static Future<Map<String, dynamic>> getBatchStudents(
      String staffId, String batchId) {
    return ApiClient.get('/api/trainer/$staffId/batches/$batchId/students');
  }
}
