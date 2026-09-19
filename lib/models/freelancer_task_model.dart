class FreelancerTaskModel {
  final String id;
  final String orgName;
  final String noOfDays;
  final String startDate;
  final String endDate;
  final String meetingLink;
  final String meetingEmail;
  final String meetingPassword;
  final String department;
  final String domain;
  final String noOfStudents;
  final String syllabus;
  final String status;
  final List<String> freelancerIds;
  final List<String> freelancerNames;

  FreelancerTaskModel({
    required this.id,
    this.orgName = '',
    this.noOfDays = '',
    this.startDate = '',
    this.endDate = '',
    this.meetingLink = '',
    this.meetingEmail = '',
    this.meetingPassword = '',
    this.department = '',
    this.domain = '',
    this.noOfStudents = '',
    this.syllabus = '',
    this.status = 'PENDING',
    this.freelancerIds = const [],
    this.freelancerNames = const [],
  });

  factory FreelancerTaskModel.fromJson(Map<String, dynamic> j) {
    return FreelancerTaskModel(
      id: j['id']?.toString() ?? '',
      orgName: j['orgName']?.toString() ?? '',
      noOfDays: j['noOfDays']?.toString() ?? '',
      startDate: j['startDate']?.toString() ?? '',
      endDate: j['endDate']?.toString() ?? '',
      meetingLink: j['meetingLink']?.toString() ?? '',
      meetingEmail: j['meetingEmail']?.toString() ?? '',
      meetingPassword: j['meetingPassword']?.toString() ?? '',
      department: j['department']?.toString() ?? '',
      domain: j['domain']?.toString() ?? '',
      noOfStudents: j['noOfStudents']?.toString() ?? '',
      syllabus: j['syllabus']?.toString() ?? '',
      status: j['status']?.toString() ?? 'PENDING',
      freelancerIds: (j['freelancerIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      freelancerNames: (j['freelancerNames'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgName': orgName,
      'noOfDays': noOfDays,
      'startDate': startDate,
      'endDate': endDate,
      'meetingLink': meetingLink,
      'meetingEmail': meetingEmail,
      'meetingPassword': meetingPassword,
      'department': department,
      'domain': domain,
      'noOfStudents': noOfStudents,
      'syllabus': syllabus,
      'status': status,
      'freelancerIds': freelancerIds,
      'freelancerNames': freelancerNames,
    };
  }
}
