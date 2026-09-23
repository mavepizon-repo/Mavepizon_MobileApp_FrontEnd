import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';
import 'dart:typed_data';

class CollegeStaffService {
  CollegeStaffService._();

  static Future<Map<String, dynamic>> getProfile() async {
    return ApiClient.get('/api/collegestaff/profile');
  }

  static Future<Map<String, dynamic>> getMyFiles() async {
    return ApiClient.get('/api/collegestaff/myfiles');
  }

  static Future<Map<String, dynamic>> uploadStudents(
    String fileName,
    Uint8List bytes,
  ) async {
    final name = fileName.toLowerCase();
    final isXls = name.endsWith('.xls');
    final contentType = isXls
        ? 'application/vnd.ms-excel'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    return ApiClient.uploadBytes(
      '/api/collegestaff/upload-students',
      bytes: bytes,
      filename: fileName,
      fileField: 'file',
      contentType: contentType,
    );
  }

  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    final email = await StorageHelper.getUserEmail();
    return ApiClient.post(
      '/api/collegestaff/change-password?email=$email&oldPassword=$oldPassword&newPassword=$newPassword',
      {},
      auth: false,
    );
  }
}
