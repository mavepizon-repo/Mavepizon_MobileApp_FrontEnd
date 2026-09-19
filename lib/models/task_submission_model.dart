class TaskSubmissionModel {
  final String id;
  final String freelancerTaskId;
  final String status;
  final String notes;
  final String feedback;

  TaskSubmissionModel({
    required this.id,
    this.freelancerTaskId = '',
    this.status = 'PENDING',
    this.notes = '',
    this.feedback = '',
  });

  factory TaskSubmissionModel.fromJson(Map<String, dynamic> j) {
    return TaskSubmissionModel(
      id: j['id']?.toString() ?? '',
      freelancerTaskId: j['freelancerTaskId']?.toString() ?? '',
      status: j['status']?.toString() ?? 'PENDING',
      notes: j['notes']?.toString() ?? '',
      feedback: j['feedback']?.toString() ?? '',
    );
  }
}
