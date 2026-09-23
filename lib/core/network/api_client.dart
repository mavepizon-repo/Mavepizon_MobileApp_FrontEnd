import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../utils/storage_helper.dart';
import '../utils/upload_validator.dart';

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
  // NOTE: no trailing slash here. Paths are joined safely in _url().
  //
  // TODO (before Play Store release): move the backend to HTTPS, e.g.
  //   'https://api.yourcompany.com'
  // Plain HTTP is blocked by Android 9+ by default and is not suitable
  // for sending login tokens.
  //
  // Override without editing code:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
  //   flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourcompany.com
  
  static const String _prodBaseUrl = 'http://187.127.143.198:8080';

  // static const String _prodBaseUrl = 'http://10.0.2.2:8080';

  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    final raw = configuredBaseUrl.isNotEmpty ? configuredBaseUrl : _prodBaseUrl;
    return _stripTrailingSlashes(raw);
  }

  // ─── URL HELPERS ──────────────────────────────────────────────
  static String _stripTrailingSlashes(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Always returns a path that starts with exactly one '/'.
  static String _normalizePath(String path) {
    var p = path.trim();
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    return '/$p';
  }

  /// Joins base URL and path with exactly one '/' between them.
  static String _url(String path) => '$baseUrl${_normalizePath(path)}';

  // ─── HEADERS ──────────────────────────────────────────────────
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

  // ─── DIO FACTORY (used by all multipart uploads) ──────────────
  static Future<Dio> _newDio({
    required bool auth,
    Duration receiveTimeout = const Duration(seconds: 120),
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: receiveTimeout,
    ));
    if (auth) {
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return dio;
  }

  // ─── GET ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    try {
      var uri = Uri.parse(_url(path));
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, _url(path))};
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
            Uri.parse(_url(path)),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(timeout ?? const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, _url(path))};
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
            Uri.parse(_url(path)),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, _url(path))};
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
            Uri.parse(_url(path)),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, _url(path))};
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
      final name = file.path.split('\\').last.split('/').last;
      final size = await file.length();
      final validationError =
          UploadValidator.validate(name, sizeBytes: size);
      if (validationError != null) {
        return {'success': false, 'message': validationError};
      }
      final dio = await _newDio(auth: auth);
      final mediaType = MediaType.parse(contentType);
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(
          file.path,
          filename: name,
          contentType: mediaType,
        ),
      });
      final res = await dio.post(_normalizePath(path), data: formData);
      return _handleDio(res);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      return {'success': false, 'message': _dioErrorMessage(e)};
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
      final validationError =
          UploadValidator.validate(filename, sizeBytes: bytes.length);
      if (validationError != null) {
        return {'success': false, 'message': validationError};
      }
      final dio = await _newDio(auth: auth);
      final formData = FormData.fromMap({
        fileField: MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      });
      final res = await dio.post(_normalizePath(path), data: formData);
      return _handleDio(res);
    } on DioException catch (e) {
      final body = e.response?.data;
      final fallback = e.message ?? 'Upload failed';
      String msg;
      if (body is Map) {
        msg = body['message']?.toString() ??
            body['error']?.toString() ??
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
      final dio = await _newDio(auth: auth);
      for (final entry in files.entries) {
        final validationError = UploadValidator.validate(
          entry.value.name,
          sizeBytes: entry.value.bytes.length,
        );
        if (validationError != null) {
          return {'success': false, 'message': validationError};
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
      final res = await dio.post(
        _normalizePath(path),
        data: formData,
        queryParameters: queryParams,
      );
      return _handleDio(res);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      return {'success': false, 'message': _dioErrorMessage(e)};
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
      final dio = await _newDio(
        auth: auth,
        receiveTimeout: const Duration(seconds: 60),
      );
      for (final entry in files.entries) {
        final validationError = UploadValidator.validate(
          entry.value.name,
          sizeBytes: entry.value.bytes.length,
        );
        if (validationError != null) {
          return {'success': false, 'message': validationError};
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
      final res = await dio.put(_normalizePath(path), data: formData);
      return _handleDio(res);
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final detail = status != null ? 'Status $status' : e.message;
      return {
        'success': false,
        'message': 'Upload failed: $detail${body != null ? ' - $body' : ''}',
      };
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
            Uri.parse(_url(path)),
            headers: await _headers(auth: auth),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'message': _parseError(e, _url(path))};
    }
  }

  // ─── RESPONSE HANDLERS ────────────────────────────────────────
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
      String? errorCode;
      if (parsed is Map) {
        errorCode = parsed['errorCode']?.toString();
        message = parsed['message']?.toString() ??
            parsed['error']?.toString() ??
            message;
      } else if (parsed is String && parsed.isNotEmpty) {
        message = parsed;
      }
      if (res.statusCode == 429) {
        // Backend (LoginRateLimitFilter) already sends a friendly message plus
        // errorCode TOO_MANY_LOGIN_ATTEMPTS with the wait time - prefer it so
        // the real rate-limit text is shown. Only fall back to the Retry-After
        // header when the server returned no message at all.
        if (message == 'Request failed (429)') {
          final retryAfter = res.headers['Retry-After'] ??
              res.headers['retry-after'] ??
              '';
          final seconds = int.tryParse(retryAfter) ?? 0;
          if (seconds > 0) {
            message = seconds >= 60
                ? 'Too many login attempts. Please try again in '
                    '${(seconds / 60).ceil()} minute${(seconds / 60).ceil() > 1 ? 's' : ''}.'
                : 'Too many login attempts. Please try again in $seconds '
                    'second${seconds > 1 ? 's' : ''}.';
          } else {
            message = 'Too many requests. Please slow down and try again.';
          }
        }
      }
      return {
        'success': false,
        'message': message,
        'status': res.statusCode,
        'data': parsed,
        if (errorCode != null) 'errorCode': errorCode,
      };
    }
  }

  /// Shared handler for Dio responses (uploads).
  static Map<String, dynamic> _handleDio(Response res) {
    final code = res.statusCode;
    if (code != null && code >= 200 && code < 300) {
      return {'success': true, 'data': res.data, 'status': code};
    }
    return {
      'success': false,
      'message': 'Upload failed ($code)',
      'data': res.data,
      'status': code,
    };
  }

  /// Shared error-message extractor for DioException (uploads).
  static String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          e.message ??
          'Upload failed';
    }
    return e.message ?? 'Upload failed';
  }
}