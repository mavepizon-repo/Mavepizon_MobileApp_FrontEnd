import '../core/network/api_client.dart';
import '../core/utils/storage_helper.dart';

class StudentCertificateService {
  StudentCertificateService._();

  static Future<Map<String, dynamic>> getMyCertificates() async {
    final studentId = await StorageHelper.getUserId();
    return ApiClient.get('/api/certificates/student/$studentId');
  }
}
