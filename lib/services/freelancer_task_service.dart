import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class FreelancerTaskService {
  FreelancerTaskService._();

  // ─── ADMIN: CREATE TASK (multipart) ────────────────────────────
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final File? syllabus = data['syllabusFile'];

    final body = {
      'orgName': data['orgName'] ?? '',
      'noOfDays': int.tryParse(data['noOfDays']?.toString() ?? ''),
      'startDate': _toDateOnly(data['startDate']?.toString() ?? ''),
      'endDate': _toDateOnly(data['endDate']?.toString() ?? ''),
      'meetingLink': data['meetingLink'] ?? '',
      'meetingEmail': data['meetingEmail'] ?? '',
      'meetingPassword': data['meetingPassword'] ?? '',
      'department': data['department'] ?? '',
      'domain': data['domain'] ?? '',
      'noOfStudents': int.tryParse(data['noOfStudents']?.toString() ?? ''),
      'status': data['status'] ?? 'PENDING',
      'freelancerIds': (data['freelancerIds'] as List? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList(),
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (syllabus != null)
          'syllabus': await MultipartFile.fromFile(syllabus.path),
      });

      final res = await dio.post(
        '${ApiClient.baseUrl}/api/admin/freelancer-tasks/create',
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

  // ─── ADMIN: UPDATE TASK (multipart) ────────────────────────────
  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final File? syllabus = data['syllabusFile'];

    final body = {
      'orgName': data['orgName'] ?? '',
      'noOfDays': int.tryParse(data['noOfDays']?.toString() ?? ''),
      'startDate': _toDateOnly(data['startDate']?.toString() ?? ''),
      'endDate': _toDateOnly(data['endDate']?.toString() ?? ''),
      'meetingLink': data['meetingLink'] ?? '',
      'meetingEmail': data['meetingEmail'] ?? '',
      'meetingPassword': data['meetingPassword'] ?? '',
      'department': data['department'] ?? '',
      'domain': data['domain'] ?? '',
      'noOfStudents': int.tryParse(data['noOfStudents']?.toString() ?? ''),
      'status': data['status'] ?? 'PENDING',
      'freelancerIds': (data['freelancerIds'] as List? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList(),
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (syllabus != null)
          'syllabus': await MultipartFile.fromFile(syllabus.path),
      });

      final res = await dio.put(
        '${ApiClient.baseUrl}/api/admin/freelancer-tasks/update/$id',
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

  // ─── ADMIN: GET BY ID ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/admin/freelancer-tasks/$id');
  }

  // ─── ADMIN: GET ALL ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAll() {
    return ApiClient.get('/api/admin/freelancer-tasks/all');
  }

  // ─── ADMIN: DELETE ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/admin/freelancer-tasks/delete/$id');
  }

  // ─── ADMIN: GET BY FREELANCER ID ───────────────────────────────
  static Future<Map<String, dynamic>> getByFreelancerId(String freelancerId) {
    return ApiClient.get('/api/admin/freelancer-tasks/freelancer/$freelancerId');
  }

  static String _toDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    if (dateStr.contains('T')) return dateStr.split('T').first;
    return dateStr;
  }
}
