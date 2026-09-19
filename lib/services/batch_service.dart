import '../core/network/api_client.dart';

class BatchService {
  BatchService._();

  // ─── ADMIN: TRAINING BATCHES ───────────────────────────────────

  // POST /api/admin/{adminId}/training-batches
  static Future<Map<String, dynamic>> createTrainingBatch(
      String adminId, Map<String, dynamic> data) {
    return ApiClient.post('/api/admin/$adminId/training-batches', data);
  }

  // POST /api/admin/batches/{batchId}/assign-staff
  static Future<Map<String, dynamic>> assignStaffToBatch(
      String batchId, Map<String, dynamic> data) {
    return ApiClient.post('/api/admin/batches/$batchId/assign-staff', data);
  }

  // POST /api/admin/batches/{batchId}/assign-staff-bulk
  static Future<Map<String, dynamic>> assignStaffToBatchBulk(
      String batchId, List<Map<String, dynamic>> staffList) {
    return ApiClient.post(
        '/api/admin/batches/$batchId/assign-staff-bulk', staffList);
  }

  // POST /api/admin/batches/{batchId}/assign-students
  static Future<Map<String, dynamic>> assignStudentsToBatch(
      String batchId, List<Map<String, dynamic>> studentList) {
    return ApiClient.post(
        '/api/admin/batches/$batchId/assign-students', studentList);
  }

  // ─── TEAM LEAD: TRAINING BATCHES ──────────────────────────────

  // POST /api/teamlead/{teamLeadId}/training-batches
  static Future<Map<String, dynamic>> createTrainingBatchTL(
      String teamLeadId, Map<String, dynamic> data) {
    return ApiClient.post('/api/teamlead/$teamLeadId/training-batches', data);
  }

  // POST /api/teamlead/{adminId}/create-batch
  static Future<Map<String, dynamic>> createBatch(
      String adminId, Map<String, dynamic> data) {
    return ApiClient.post('/api/teamlead/$adminId/create-batch', data);
  }

  // POST /api/teamlead/{teamLeadId}/batches/{batchId}/assign-staff-bulk
  static Future<Map<String, dynamic>> assignStaffToBatchBulkTL(
      String teamLeadId, String batchId, List<Map<String, dynamic>> staffList) {
    return ApiClient.post(
        '/api/teamlead/$teamLeadId/batches/$batchId/assign-staff-bulk',
        staffList);
  }

  // POST /api/teamlead/batches/{batchId}/assign-students
  static Future<Map<String, dynamic>> assignStudentsToBatchTL(
      String batchId, List<Map<String, dynamic>> studentList) {
    return ApiClient.post(
        '/api/teamlead/batches/$batchId/assign-students', studentList);
  }
}
