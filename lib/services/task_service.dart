import '../core/network/api_client.dart';

class TaskService {
  TaskService._();

  // ─── GET ALL TASKS (Team Lead) ────────────────────────────────
  static Future<Map<String, dynamic>> getAll({
    String? staffId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    if (staffId != null && staffId.isNotEmpty) {
      return ApiClient.get('/api/tasks/staff/$staffId');
    }

    if (status != null && status.isNotEmpty && status != 'ALL') {
      return ApiClient.get('/api/tasks/status/$status');
    }

    if (startDate != null && endDate != null) {
      final start = _toDateOnly(startDate);
      final end = _toDateOnly(endDate);
      return ApiClient.get(
        '/api/tasks/date-range',
        queryParams: {'start': start, 'end': end},
      );
    }

    return ApiClient.get('/api/task/get-all');
  }

  // ─── ASSIGN TASK (single staff) ──────────────────────────────
  static Future<Map<String, dynamic>> assign(Map<String, dynamic> data) async {
    final body = {
      'staffId': int.tryParse(data['staffId']?.toString() ?? '0') ?? 0,
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'deadline': _toDateOnly(data['deadline']?.toString() ?? ''),
      'taskType': data['taskType'] ?? 'DEVELOPMENT',
      'priority': data['priority'] ?? 'MEDIUM',
      'estimatedHours': data['estimatedHours'] ?? 0,
      'remarks': data['remarks'] ?? '',
      if (data['assignedDate'] != null)
        'assignedDate': _toDateOnly(data['assignedDate'].toString()),
    };

    return ApiClient.post('/api/task/assign', body);
  }

  // ─── ASSIGN TASK (group: multiple staff) ──────────────────────
  static Future<Map<String, dynamic>> assignGroup(
      Map<String, dynamic> data, List<int> staffIds) async {
    final body = {
      'staffIds': staffIds,
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'deadline': _toDateOnly(data['deadline']?.toString() ?? ''),
      'taskType': data['taskType'] ?? 'DEVELOPMENT',
      'priority': data['priority'] ?? 'MEDIUM',
      'estimatedHours': data['estimatedHours'] ?? 0,
      'remarks': data['remarks'] ?? '',
      if (data['assignedDate'] != null)
        'assignedDate': _toDateOnly(data['assignedDate'].toString()),
    };

    return ApiClient.post('/api/task/assign-some', body);
  }

  // ─── ASSIGN TASK (all staff under teamlead) ──────────────────
  static Future<Map<String, dynamic>> assignAll(
      Map<String, dynamic> data) async {
    final body = {
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'deadline': _toDateOnly(data['deadline']?.toString() ?? ''),
      'taskType': data['taskType'] ?? 'DEVELOPMENT',
      'priority': data['priority'] ?? 'MEDIUM',
      'estimatedHours': data['estimatedHours'] ?? 0,
      'remarks': data['remarks'] ?? '',
      if (data['assignedDate'] != null)
        'assignedDate': _toDateOnly(data['assignedDate'].toString()),
    };

    return ApiClient.post('/api/task/assign-all-by-teamlead', body);
  }

  // ─── UPDATE TASK ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> update(
      String taskId, Map<String, dynamic> data) async {
    final body = <String, dynamic>{};

    if (data['title'] != null) body['title'] = data['title'];
    if (data['description'] != null) body['description'] = data['description'];
    if (data['priority'] != null) body['priority'] = data['priority'];
    if (data['taskType'] != null) body['taskType'] = data['taskType'];
    if (data['deadline'] != null) {
      body['deadline'] = _toDateOnly(data['deadline'].toString());
    }
    if (data['estimatedHours'] != null) {
      body['estimatedHours'] = data['estimatedHours'];
    }
    if (data['assignedDate'] != null) {
      body['assignedDate'] = _toDateOnly(data['assignedDate'].toString());
    }
    if (data['progressPercentage'] != null) {
      body['progressPercentage'] = data['progressPercentage'];
    }
    if (data['status'] != null) body['status'] = data['status'];
    if (data['workDoneToday'] != null) {
      body['workDoneToday'] = data['workDoneToday'];
    }
    if (data['blockers'] != null) body['blockers'] = data['blockers'];
    if (data['remarks'] != null) body['remarks'] = data['remarks'];
    if (data['attachmentUrl'] != null) {
      body['attachmentUrl'] = data['attachmentUrl'];
    }

    if (body.isEmpty) {
      body['progressPercentage'] = 0;
      body['status'] = 'IN_PROGRESS';
    }

    return ApiClient.put('/api/task/update/$taskId', body);
  }

  // ─── DELETE TASK ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String taskId) async {
    return ApiClient.delete('/api/task/$taskId');
  }

  // ─── REVIEW TASK ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> reviewTask(
      String taskId, Map<String, dynamic> data) async {
    final body = {
      'verificationStatus': data['verificationStatus'] ?? 'APPROVED',
      'reviewComment': data['reviewComment'] ?? '',
      'pointsDeduction': data['pointsDeduction'] ?? 0,
      'reworkNotes': data['reworkNotes'] ?? '',
    };

    return ApiClient.post('/api/task/review/$taskId', body);
  }

  // ─── GET TASK BY ID (Team Lead) ───────────────────────────────
  static Future<Map<String, dynamic>> getById(String taskId) async {
    return ApiClient.get('/api/tasks/$taskId');
  }

  // ─── TOGGLE STATUS ────────────────────────────────────────────
  static Future<Map<String, dynamic>> toggleStatus(
      String taskId, String status) async {
    return ApiClient.patch('/api/task/$taskId/status', {'status': status});
  }

  // ─── ADMIN ASSIGN TASK ─────────────────────────────────────────
  static Future<Map<String, dynamic>> assignTaskAdmin(
      String adminId, Map<String, dynamic> data) async {
    final body = {
      'staffId': int.tryParse(data['staffId']?.toString() ?? '0') ?? 0,
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'deadline': _toDateOnly(data['deadline']?.toString() ?? ''),
      'taskType': data['taskType'] ?? 'DEVELOPMENT',
      'priority': data['priority'] ?? 'MEDIUM',
      'estimatedHours': data['estimatedHours'] ?? 0,
      'remarks': data['remarks'] ?? '',
      if (data['assignedDate'] != null)
        'assignedDate': _toDateOnly(data['assignedDate'].toString()),
    };
    return ApiClient.post('/api/admin/$adminId/assign-task', body);
  }

  // ─── ADMIN GET TASK BY ID ─────────────────────────────────────
  static Future<Map<String, dynamic>> getTaskByIdAdmin(String taskId) async {
    return ApiClient.get('/api/admin/tasks/$taskId');
  }

  // ─── ADMIN UPDATE TASK ─────────────────────────────────────────
  static Future<Map<String, dynamic>> updateTaskAdmin(
      String taskId, Map<String, dynamic> data) async {
    return ApiClient.put('/api/admin/tasks/$taskId', data);
  }

  // ─── ADMIN DELETE TASK ─────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteTaskAdmin(String taskId) async {
    return ApiClient.delete('/api/admin/tasks/$taskId');
  }

  // ─── ADMIN REVIEW TASK ─────────────────────────────────────────
  static Future<Map<String, dynamic>> reviewTaskAdmin(
      String taskId, String adminId, Map<String, dynamic> data) async {
    return ApiClient.post('/api/admin/tasks/$taskId/review?adminId=$adminId', data);
  }

  // ─── ADMIN: GET ALL TASKS ─────────────────────────────────────
  static Future<Map<String, dynamic>> getAllTasks() {
    return ApiClient.get('/api/admin/tasks');
  }

  // ─── HELPER: Convert ISO string to date-only yyyy-MM-dd ───────
  static String _toDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    if (dateStr.contains('T')) return dateStr.split('T').first;
    return dateStr;
  }
}
