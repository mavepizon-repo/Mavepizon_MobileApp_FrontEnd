import '../core/network/api_client.dart';

class AdminTeamLeadService {
  AdminTeamLeadService._();

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    // Backend generates the Team Lead ID (AdminService.generateTeamLeadId)
    // from the branch and persists createdBy from the token.
    return ApiClient.post('/api/admin/teamlead', data);
  }

  static Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'asc',
  }) {
    return ApiClient.get('/api/admin/teamlead', queryParams: {
      'page': '$page',
      'size': '$size',
      'sort': sort,
      'direction': direction,
    });
  }

  static Future<Map<String, dynamic>> getById(String id) {
    return ApiClient.get('/api/admin/teamlead/$id');
  }

  static Future<Map<String, dynamic>> getPerformance(String id) {
    return ApiClient.get('/api/admin/teamlead/$id/performance');
  }

  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) {
    return ApiClient.put('/api/admin/teamlead/$id', data);
  }

  static Future<Map<String, dynamic>> toggleStatus(
      String id, bool active) {
    return ApiClient.patch('/api/admin/teamlead/$id/status?active=$active', {});
  }

  static Future<Map<String, dynamic>> delete(String id) {
    return ApiClient.delete('/api/admin/teamlead/$id');
  }
}
