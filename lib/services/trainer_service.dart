import 'dart:io';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';
import '../core/utils/upload_validator.dart';
import 'package:dio/dio.dart';

class TrainerService {
  TrainerService._();

  // ─── SHARED FETCH: trainer's assigned courses ────────────────
  // Backend has no /api/trainer/{staffId}/batches endpoints.
  // Staff are linked to courses through CourseStaffAssignment, so
  // we read that list and keep only courses assigned to this staff.
  static Future<Map<String, dynamic>> _fetchAssignmentCards(
    String staffId, {
    bool? online,
    bool? offline,
  }) async {
    final result = await ApiClient.get(
      '/api/course-staff-assignment/get-all',
      queryParams: const {'size': '500'},
    );
    if (result['success'] != true) return result;

    final data = result['data'];
    final List<dynamic> list;
    if (data is Map && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    } else {
      list = const [];
    }

    final cards = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final item in list) {
      if (item is! Map) continue;
      final course = item['course'];
      if (course is! Map) continue;
      final courseId = course['id']?.toString();
      if (courseId == null || courseId.isEmpty) continue;

      final isOnline = item['onlineStaffId']?.toString() == staffId;
      final isTisa = item['tisaiyanvilaiStaffId']?.toString() == staffId;
      final isTiru = item['tirunelveliStaffId']?.toString() == staffId;
      if (!isOnline && !isTisa && !isTiru) continue;
      if (online == true && !isOnline) continue;
      if (offline == true && !(isTisa || isTiru)) continue;
      if (!seen.add(courseId)) continue;

      var zoomLink = course['zoomLink']?.toString().isNotEmpty == true
          ? course['zoomLink'].toString()
          : '';
      var studentCount = 0;
      if (isOnline) {
        if (item['onlineZoomLink']?.toString().isNotEmpty == true) {
          zoomLink = item['onlineZoomLink'].toString();
        }
        studentCount =
            (course['registeredSeatsOnline'] as num?)?.toInt() ?? 0;
      } else if (isTisa) {
        if (item['tisaiyanvilaiZoomLink']?.toString().isNotEmpty == true) {
          zoomLink = item['tisaiyanvilaiZoomLink'].toString();
        }
        studentCount =
            (course['registeredSeatsTisaiyanvilai'] as num?)?.toInt() ?? 0;
      } else if (isTiru) {
        if (item['tirunelveliZoomLink']?.toString().isNotEmpty == true) {
          zoomLink = item['tirunelveliZoomLink'].toString();
        }
        studentCount =
            (course['registeredSeatsTirunelveli'] as num?)?.toInt() ?? 0;
      }
      if (studentCount == 0) {
        studentCount =
            ((course['registeredSeatsOnline'] as num?)?.toInt() ?? 0) +
                ((course['registeredSeatsTisaiyanvilai'] as num?)?.toInt() ??
                    0) +
                ((course['registeredSeatsTirunelveli'] as num?)?.toInt() ??
                    0);
      }

      cards.add({
        'batchId': courseId,
        'courseId': courseId,
        'batchCode': course['batchId']?.toString() ??
            course['courseCode']?.toString() ??
            '',
        'batchName': course['courseName']?.toString() ??
            course['courseCode']?.toString() ??
            'Batch',
        'zoomLink': zoomLink,
        'studentCount': studentCount,
        'isOnline': isOnline,
        'isOffline': isTisa || isTiru,
      });
    }
    return {'success': true, 'data': cards};
  }

  static Future<Map<String, dynamic>> getBatches(String staffId) {
    return _fetchAssignmentCards(staffId);
  }

  static Future<Map<String, dynamic>> getOnlineBatches(String staffId) {
    return _fetchAssignmentCards(staffId, online: true);
  }

  static Future<Map<String, dynamic>> getOfflineBatches(String staffId) {
    return _fetchAssignmentCards(staffId, offline: true);
  }

  // ─── MARK ATTENDANCE ──────────────────────────────────────────
  static Future<Map<String, dynamic>> markAttendance(
      String staffId, Map<String, dynamic> data) {
    return ApiClient.post('/api/trainer/$staffId/attendance', data);
  }

  // ─── UPLOAD COURSE MATERIAL ───────────────────────────────────
  static Future<Map<String, dynamic>> uploadMaterial(
    String staffId,
    String courseId,
    String title,
    File file,
  ) async {
    try {
      final name = file.path.split('\\').last.split('/').last;
      int size = 0;
      try {
        size = await file.length();
      } catch (_) {}
      final validationError =
          UploadValidator.validate(name, sizeBytes: size);
      if (validationError != null) {
        return {'success': false, 'message': validationError};
      }
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
          ? (e.response!.data as Map)['message']?.toString() ??
              (e.response!.data as Map)['error']?.toString() ??
              e.message
          : e.message;
      return {'success': false, 'message': msg ?? 'Upload failed'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // ─── BATCH STUDENTS (course roster) ───────────────────────────
  // Backend roster endpoint: /api/student-course/course/{courseId}
  static Future<Map<String, dynamic>> getBatchStudents(
      String staffId, String courseId) async {
    final result =
        await ApiClient.get('/api/student-course/course/$courseId');
    if (result['success'] != true) return result;

    final data = result['data'];
    final List<dynamic> list = data is List ? data : const [];
    final students = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final student = item['student'];
      if (student is! Map) continue;
      final id = student['id']?.toString();
      if (id == null || id.isEmpty) continue;
      students.add({
        'studentId': id,
        'studentName': student['name']?.toString() ??
            student['studentId']?.toString() ??
            'Unknown',
      });
    }
    return {'success': true, 'data': students};
  }

  // ─── DASHBOARD COUNTS ─────────────────────────────────────────
  // Derived from the real endpoints instead of a /dashboard call.
  static Future<Map<String, dynamic>> getDashboard(String staffId) async {
    final result = await _fetchAssignmentCards(staffId);
    final List<dynamic> cards =
        result['success'] == true && result['data'] is List
            ? result['data'] as List
            : const [];
    if (result['success'] != true) return result;

    var onlineBatches = 0;
    var offlineBatches = 0;
    var totalStudents = 0;
    for (final c in cards) {
      if (c is! Map) continue;
      totalStudents += (c['studentCount'] as num?)?.toInt() ?? 0;
      if (c['isOnline'] == true) onlineBatches++;
      if (c['isOffline'] == true) offlineBatches++;
    }

    // Today's attendance via real endpoint:
    // /api/trainer/{staffId}/courses/{courseId}/attendance/date?date=...
    var todayAttendance = 0;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    for (final c in cards) {
      if (c is! Map) continue;
      final courseId = c['batchId']?.toString();
      if (courseId == null || courseId.isEmpty) continue;
      final attRes = await ApiClient.get(
        '/api/trainer/$staffId/courses/$courseId/attendance/date',
        queryParams: {'date': today},
      );
      if (attRes['success'] == true) {
        final d = attRes['data'];
        if (d is List) {
          todayAttendance += d.length;
        } else if (d is Map && d['content'] is List) {
          todayAttendance += (d['content'] as List).length;
        }
      }
    }

    return {
      'success': true,
      'data': {
        'assignedBatches': cards.length,
        'onlineBatches': onlineBatches,
        'offlineBatches': offlineBatches,
        'attendanceToday': todayAttendance,
        'totalStudents': totalStudents,
      },
    };
  }
}