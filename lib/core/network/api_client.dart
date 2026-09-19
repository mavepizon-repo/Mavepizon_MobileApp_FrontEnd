import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../utils/storage_helper.dart';

class ApiClient {
  ApiClient._();

  static String _parseError(dynamic e, String uri) {
    if (kIsWeb && e is http.ClientException && e.message.contains('Failed to fetch')) {
      return 'CORS error: Backend at $uri blocked the request. '
          'Add CORS config in Spring Boot (CorsConfig / @CrossOrigin) '
          'or run Chrome with --disable-web-security for development:\n'
          '  flutter run -d chrome --web-browser-flag "--disable-web-security"';
    }
    if (e is SocketException) {
      return 'No internet connection';
    }
    return 'Request failed: ${e.toString()}';
  }

  // ─── CONFIGURE YOUR BACKEND ADDRESS ──────────────────────────
  // Production backend (deployed on Render).
  // Override for local testing with, for example:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
  static const String _prodBaseUrl =
      'https://mavepizon-app-backend-up2x.onrender.com';

  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    // Default: always hit the deployed backend unless overridden above.
    return _prodBaseUrl;
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── GET ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, '$baseUrl$path')};
    }
  }

  // ─── POST ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String path,
    dynamic body, {
    bool auth = true,
    Duration? timeout,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, '$baseUrl$path')};
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String path,
    dynamic body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, '$baseUrl$path')};
    }
  }

  // ─── PATCH ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, '$baseUrl$path')};
    }
  }

  // ─── FILE UPLOAD (POST multipart) ───────────────────────────
  static Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    String fileField = 'file',
    String contentType = 'application/octet-stream',
    bool auth = true,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ));
      if (auth) {
        final token = await StorageHelper.getToken();
        if (token != null && token.isNotEmpty) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }
      }
      final mediaType = MediaType.parse(contentType);
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('\\').last.split('/').last,
          contentType: mediaType,
        ),
      });
      final res = await dio.post(path, data: formData);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'data': res.data,
        'status': res.statusCode,
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ??
              (e.response!.data as Map)['message']?.toString() ??
              e.message
          : e.message;
      return {'success': false, 'message': msg ?? 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── BYTES UPLOAD (web-safe single file POST multipart) ───────
  static Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    String fileField = 'file',
    String contentType = 'application/octet-stream',
    bool auth = true,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ));
      if (auth) {
        final token = await StorageHelper.getToken();
        if (token != null && token.isNotEmpty) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }
      }
      final formData = FormData.fromMap({
        fileField: MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      });
      final res = await dio.post(path, data: formData);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'data': res.data,
        'status': res.statusCode,
      };
    } on DioException catch (e) {
      final body = e.response?.data;
      final fallback = e.message ?? 'Upload failed';
      String msg;
      if (body is Map) {
        msg = body['error']?.toString() ??
            body['message']?.toString() ??
            body['path']?.toString() ??
            fallback;
      } else if (body is String && body.isNotEmpty) {
        msg = body;
      } else {
        msg = fallback;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── MULTIPART POST (multiple file upload) ───────────────────
  static Future<Map<String, dynamic>> uploadFiles(
    String path,
    Map<String, ({Uint8List bytes, String name})> files, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ));
      if (auth) {
        final token = await StorageHelper.getToken();
        if (token != null && token.isNotEmpty) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }
      }
      final formData = FormData();
      for (final entry in files.entries) {
        formData.files.add(MapEntry(
          entry.key,
          MultipartFile.fromBytes(
            entry.value.bytes,
            filename: entry.value.name,
          ),
        ));
      }
      final res = await dio.post(path, data: formData, queryParameters: queryParams);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'data': res.data,
        'status': res.statusCode,
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ??
              (e.response!.data as Map)['message']?.toString() ??
              e.message
          : e.message;
      return {'success': false, 'message': msg ?? 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── MULTIPART PUT (file upload) ─────────────────────────────
  static Future<Map<String, dynamic>> multipartPut(
    String path,
    Map<String, ({Uint8List bytes, String name})> files, {
    bool auth = true,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      if (auth) {
        final token = await StorageHelper.getToken();
        if (token != null && token.isNotEmpty) {
          dio.options.headers['Authorization'] = 'Bearer $token';
        }
      }
      final formData = FormData();
      for (final entry in files.entries) {
        formData.files.add(MapEntry(
          entry.key,
          MultipartFile.fromBytes(
            entry.value.bytes,
            filename: entry.value.name,
          ),
        ));
      }
      final res = await dio.put(path, data: formData);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        return {'success': true, 'data': res.data, 'status': res.statusCode};
      }
      return {
        'success': false,
        'message': 'Upload failed (${res.statusCode})',
        'data': res.data,
        'status': res.statusCode,
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final detail = status != null ? 'Status $status' : e.message;
      return {'success': false, 'message': 'Upload failed: $detail${body != null ? ' - $body' : ''}'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, '$baseUrl$path')};
    }
  }

  // ─── RESPONSE HANDLER ─────────────────────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final body = res.body;

    dynamic parsed;
    try {
      parsed = jsonDecode(body);
    } catch (_) {
      parsed = body;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': parsed, 'status': res.statusCode};
    } else {
      String message = 'Request failed (${res.statusCode})';
      if (parsed is Map) {
        message = parsed['message']?.toString() ??
            parsed['error']?.toString() ??
            message;
      } else if (parsed is String && parsed.isNotEmpty) {
        message = parsed;
      }
      return {
        'success': false,
        'message': message,
        'status': res.statusCode,
        'data': parsed,
      };
    }
  }
}