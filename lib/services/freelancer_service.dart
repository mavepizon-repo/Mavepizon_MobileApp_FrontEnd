import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class FreelancerService {
  FreelancerService._();

  // ─── FREELANCER LOGIN ─────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) {
    return ApiClient.post(
      '/api/freelancer/login',
      {'email': email, 'password': password},
      auth: false,
    );
  }

  // ─── FREELANCER: GET MY TASKS ─────────────────────────────────
  static Future<Map<String, dynamic>> getMyTasks() {
    return ApiClient.get('/api/freelancer/mytasks');
  }

  // ─── ADMIN: CREATE FREELANCER (multipart) ─────────────────────
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final File? profile = data['profileFile'];
    final File? aadhaar = data['aadhaarFile'];
    final File? resume = data['resumeFile'];

    final body = {
      'name': data['name'] ?? '',
      'yearOfPassing': int.tryParse(data['yearOfPassing']?.toString() ?? ''),
      'experience': double.tryParse(data['experience']?.toString() ?? ''),
      'district': data['district'] ?? '',
      'address': data['address'] ?? '',
      'mobileNo': data['mobileNo'] ?? '',
      'email': data['email'] ?? '',
      'password': data['password'] ?? '',
      'resume': data['resume'] ?? '',
      'aadhaar': data['aadhaar'] ?? '',
      'techStackNames': data['techStackNames'] ?? [],
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (profile != null)
          'profile': await MultipartFile.fromFile(profile.path),
        if (aadhaar != null)
          'aadhaar': await MultipartFile.fromFile(aadhaar.path),
        if (resume != null)
          'resume': await MultipartFile.fromFile(resume.path),
      });

      final res = await dio.post(
        '${ApiClient.baseUrl}/api/admin/freelancers/create',
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

  // ─── ADMIN: UPDATE FREELANCER (multipart) ─────────────────────
  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final File? profile = data['profileFile'];
    final File? aadhaar = data['aadhaarFile'];
    final File? resume = data['resumeFile'];

    final body = {
      'name': data['name'] ?? '',
      'yearOfPassing': int.tryParse(data['yearOfPassing']?.toString() ?? ''),
      'experience': double.tryParse(data['experience']?.toString() ?? ''),
      'district': data['district'] ?? '',
      'address': data['address'] ?? '',
      'mobileNo': data['mobileNo'] ?? '',
      'email': data['email'] ?? '',
      'password': data['password'] ?? '',
      'resume': data['resume'] ?? '',
      'aadhaar': data['aadhaar'] ?? '',
      'techStackNames': data['techStackNames'] ?? [],
    };

    try {
      final token = await StorageHelper.getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(body),
          contentType: MediaType('application', 'json'),
        ),
        if (profile != null)
          'profile': await MultipartFile.fromFile(profile.path),
        if (aadhaar != null)
          'aadhaar': await MultipartFile.fromFile(aadhaar.path),
        if (resume != null)
          'resume': await MultipartFile.fromFile(resume.path),
      });

      final res = await dio.put(
        '${ApiClient.baseUrl}/api/admin/freelancers/update/$id',
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
    return ApiClient.get('/api/admin/freelancers/$id');
  }

  // ─── ADMIN: GET ALL ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'asc',
  }) {
    return ApiClient.get('/api/admin/freelancers/get-all', queryParams: {
      'page': '$page',
      'size': '$size',
      'sort': sort,
      'direction': direction,
    });
  }

  // ─── ADMIN: DELETE ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/admin/freelancers/delete/$id');
  }

  // ─── ADMIN: FILTER BY DISTRICT ─────────────────────────────────
  static Future<Map<String, dynamic>> filterByDistrict(String district) {
    return ApiClient.get('/api/admin/freelancers/filter/district/$district');
  }

  // ─── ADMIN: FILTER BY TECH STACK ───────────────────────────────
  static Future<Map<String, dynamic>> filterByTechStack(String techStack) {
    return ApiClient.get('/api/admin/freelancers/filter/techstack/$techStack');
  }
}
