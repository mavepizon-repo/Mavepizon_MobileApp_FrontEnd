import '../core/network/api_client.dart';

class AdminStaffService {
  AdminStaffService._();

  static Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'asc',
  }) {
    return ApiClient.get('/api/admin/staff', queryParams: {
      'page': '$page',
      'size': '$size',
      'sort': sort,
      'direction': direction,
    });
  }

  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/admin/staff/$id');
  }

  static Future<Map<String, dynamic>> create(
      String adminId, Map<String, dynamic> data) {
    return ApiClient.post('/api/admin/$adminId/staff', data);
  }

  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) {
    return ApiClient.put('/api/admin/staff/$id', data);
  }

  /// Deletes a staff member using the cascade endpoint that the backend uses
  /// to clean up related permission / leave / task records before removing the
  /// staff. The plain admin delete (`DELETE /api/admin/staff/{id}`) fails with
  /// a foreign-key error whenever the staff has any dependent records, so the
  /// frontend calls the cascade-capable backend endpoint instead:
  /// `DELETE /api/staff/{staffId}` (TeamLeadController).
  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/staff/$id');
  }

  static Future<Map<String, dynamic>> getPendingApprovals() {
    return ApiClient.get('/api/admin/staff/pending-approvals');
  }

  static Future<Map<String, dynamic>> approveStaff(String staffId) {
    return ApiClient.patch('/api/admin/staff/$staffId/approve', {});
  }

  /// Soft-delete fallback. The backend refuses to hard-delete a staff member
  /// that still has attendance / telecalling / other dependent records (FK
  /// constraint -> 500), and there is no backend endpoint to purge those, so
  /// the frontend deactivates the staff via the existing status endpoint
  /// instead. Deactivated staff are hidden from the Admin Staff Monitoring
  /// list (with the "Show inactive" toggle still available).
  static Future<Map<String, dynamic>> setStatus(String id, bool active) {
    return ApiClient.patch(
      '/api/staff/$id/status?active=${active ? 'true' : 'false'}',
      <String, dynamic>{},
    );
  }
}
