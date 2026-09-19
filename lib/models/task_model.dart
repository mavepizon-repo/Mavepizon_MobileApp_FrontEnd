class TaskModel {
  final String id;
  final String title; 
  final String description;
  final String staffId; 
  final String staffName; 
  final String staffRole; 
  final String teamLeadId;
  final String teamLeadName;
  final String priority; 
  final String startDate; 
  final String deadline;
  final String status; 
  final String taskType;
  final String? remarks;
  final String? completionDate;
  final int progress;
  final int estimatedHours;

  String? get assignedToName => staffName.isNotEmpty ? staffName : null;
  String? get assignedToId => staffId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.teamLeadId,
    required this.teamLeadName,
    required this.priority,
    required this.startDate,
    required this.deadline,
    required this.status,
    required this.taskType,
    this.remarks,
    this.completionDate,
    this.progress = 0,
    this.estimatedHours = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> j) {
    return TaskModel(
      id: j['taskId']?.toString() ?? j['id']?.toString() ?? '',
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      staffId: j['staffId']?.toString() ?? '',
      staffName: j['staffName'] ?? '',
      staffRole: j['staffRole'] ?? '',
      teamLeadId: j['teamLeadId']?.toString() ?? '',
      teamLeadName: j['teamLeadName'] ?? '',
      priority: j['priority']?.toString() ?? 'MEDIUM',
      startDate: j['assignedDate']?.toString() ?? '',
      deadline: j['deadline']?.toString() ?? '',
      status: j['status']?.toString() ?? 'ASSIGNED',
      taskType: j['taskType']?.toString() ?? 'DEVELOPMENT',
      remarks: j['remarks']?.toString(),
      completionDate: j['completionDate']?.toString(),
      progress: j['progress'] ?? 0,
      estimatedHours: j['estimatedHours'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': id,
        'title': title,
        'description': description,
        'staffId': int.tryParse(staffId) ?? 0,
        'priority': priority,
        'deadline': deadline,
        'status': status,
        'remarks': remarks,
        'progress': progress,
      };
}
