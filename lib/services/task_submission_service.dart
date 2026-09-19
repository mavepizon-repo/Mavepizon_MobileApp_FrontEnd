import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class TaskSubmissionService {
  TaskSubmissionService._();

  // ─── CREATE SUBMISSION (multipart) ─────────────────────────────
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final File? notesFile = data['notesFile'];

    final body = {
      'freelancerTaskId': int.tryParse(data['freelancerTaskId']?.toString() ?? '0') ?? 0,
      'status': data['status'] ?? 'PENDING',
      'feedback': data['feedback'] ?? '',
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (notesFile != null)
          'notes': await MultipartFile.fromFile(notesFile.path),
      });

      final res = await dio.post(
        '${ApiClient.baseUrl}/api/freelancer/task-submissions/submit',
        data: formData,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'status': res.statusCode,
      };
    } on DioException catch (e) {
      String msg = 'Upload failed';
      if (e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            (e.response!.data as Map)['error']?.toString() ??
            msg;
      } else if (e.message != null) {
        msg = e.message!;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── UPDATE SUBMISSION (multipart) ─────────────────────────────
  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final File? notesFile = data['notesFile'];

    final body = {
      'freelancerTaskId': int.tryParse(data['freelancerTaskId']?.toString() ?? '0') ?? 0,
      'status': data['status'] ?? 'PENDING',
      'feedback': data['feedback'] ?? '',
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (notesFile != null)
          'notes': await MultipartFile.fromFile(notesFile.path),
      });

      final res = await dio.put(
        '${ApiClient.baseUrl}/api/freelancer/task-submissions/update/$id',
        data: formData,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'status': res.statusCode,
      };
    } on DioException catch (e) {
      String msg = 'Upload failed';
      if (e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            (e.response!.data as Map)['error']?.toString() ??
            msg;
      } else if (e.message != null) {
        msg = e.message!;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── GET BY ID ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/freelancer/task-submissions/$id');
  }

  // ─── GET BY FREELANCER TASK ID ─────────────────────────────────
  static Future<Map<String, dynamic>> getByFreelancerTaskId(String taskId) {
    return ApiClient.get('/api/freelancer/task-submissions/task/$taskId');
  }

  // ─── GET ALL ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/freelancer/task-submissions/get-all');
  }

  // ─── DELETE ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/freelancer/task-submissions/delete/$id');
  }
}
