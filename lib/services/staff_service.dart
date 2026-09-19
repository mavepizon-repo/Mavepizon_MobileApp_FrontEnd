import 'dart:typed_data';
import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StaffService {
  StaffService._();

  static Future<Map<String, dynamic>> getAll() async {
    return ApiClient.get('/api/teamlead/staff/all-by-branch');
  }

  static Future<Map<String, dynamic>> getById(String staffId) async {
    return ApiClient.get('/api/staff/$staffId');
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final body = <String, dynamic>{
      'name': data['name'] ?? '',
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'mobileNumber': data['mobileNumber'] ?? '',
      'password': data['password'] ?? '',
      'degree': data['degree'] ?? '',
      'experience': data['experience'] ?? 0,
      'previousCompany': data['previousCompany'] ?? '',
      'bloodGroup': data['bloodGroup'] ?? '',
      'gender': data['gender'] ?? 'Male',
      'branch': data['branch'] ?? '',
      'skills': data['skills'] ?? '',
      'category': data['category'] ?? data['role'] ?? 'DEVELOPER',
      'role': data['role'] ?? data['category'] ?? 'DEVELOPER',
      'nativePlace': data['nativePlace'] ?? '',
      'yearPassedOut': data['yearPassedOut'] ?? 0,
      'shiftStartTime': data['shiftStartTime'] ?? '',
      'shiftEndTime': data['shiftEndTime'] ?? '',
    };
    if (data['joiningDate'] != null && (data['joiningDate'] as String).isNotEmpty) {
      body['joiningDate'] = data['joiningDate'];
    }
    final result = await ApiClient.post('/api/office-staff/create', body);
    if (result['success'] == true) {
      final dataMap = result['data'];
      final staffId = dataMap is Map ? dataMap['staffId']?.toString() : null;
      if (staffId != null && staffId.isNotEmpty) {
        await StorageHelper.saveStaffShiftTime(
          staffId,
          shiftStartTime: body['shiftStartTime'] ?? '',
          shiftEndTime: body['shiftEndTime'] ?? '',
        );
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> update(
      String staffId, Map<String, dynamic> data) async {
    final body = <String, dynamic>{
      'name': data['name'] ?? '',
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'mobileNumber': data['mobileNumber'] ?? '',
      'degree': data['degree'] ?? '',
      'experience': data['experience'] ?? 0,
      'previousCompany': data['previousCompany'] ?? '',
      'bloodGroup': data['bloodGroup'] ?? '',
      'gender': data['gender'] ?? 'Male',
      'branch': data['branch'] ?? '',
      'skills': data['skills'] ?? '',
      'category': data['category'] ?? data['role'] ?? 'DEVELOPER',
      'role': data['role'] ?? data['category'] ?? 'DEVELOPER',
      'nativePlace': data['nativePlace'] ?? '',
      'yearPassedOut': data['yearPassedOut'] ?? 0,
      'shiftStartTime': data['shiftStartTime'] ?? '',
      'shiftEndTime': data['shiftEndTime'] ?? '',
    };
    if (data['joiningDate'] != null && (data['joiningDate'] as String).isNotEmpty) {
      body['joiningDate'] = data['joiningDate'];
    }
    final result = await ApiClient.put('/api/staff/update/$staffId', body);
    if (result['success'] == true && staffId.isNotEmpty) {
      await StorageHelper.saveStaffShiftTime(
        staffId,
        shiftStartTime: body['shiftStartTime'] ?? '',
        shiftEndTime: body['shiftEndTime'] ?? '',
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> toggleStatus(
      String staffId, bool active) async {
    return ApiClient.patch('/api/staff/$staffId/status?active=$active', {});
  }

  static Future<Map<String, dynamic>> delete(String staffId) async {
    return ApiClient.delete('/api/staff/$staffId');
  }

  static Future<Map<String, dynamic>> uploadFiles(
    String staffId, {
    ({Uint8List bytes, String name})? profile,
    ({Uint8List bytes, String name})? aadhaar,
    ({Uint8List bytes, String name})? resume,
  }) async {
    final files = <String, ({Uint8List bytes, String name})>{};
    if (profile != null) files['profile'] = profile;
    if (aadhaar != null) files['aadhaar'] = aadhaar;
    if (resume != null) files['resume'] = resume;
    if (files.isEmpty) {
      return {'success': true, 'message': 'No files to upload'};
    }
    return ApiClient.multipartPut('/api/office-staff/update-files/$staffId', files);
  }
}
