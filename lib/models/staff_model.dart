class StaffModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String mobileNumber;
  final String degree;
  final String role;
  final String category;
  final String branch;
  final String gender;
  final String nativePlace;
  final String joiningDate;
  final String status;
  final String createdAt;
  final String? updatedAt;
  final String? profilePhoto;
  final String? resume;
  final String? aadhar;
  final String? experience;
  final String? previousCompany;
  final String? bloodGroup;
  final String? experienceCertificate;
  final String? createdByAdmin;
  final int? yearPassedOut;
  final List<String> skills;
  final double performanceScore;
  final int totalAssignedTasks;
  final int totalCompletedTasks;
  final int totalPendingTasks;
  final String shiftStartTime;
  final String shiftEndTime;

  String get fullName => name;
  String get phone => mobileNumber;
  String get qualification => degree;
  String get branchId => branch;

  StaffModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.degree,
    required this.role,
    required this.category,
    required this.branch,
    this.gender = '',
    this.nativePlace = '',
    required this.joiningDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.profilePhoto,
    this.resume,
    this.aadhar,
    this.experience,
    this.previousCompany,
    this.bloodGroup,
    this.experienceCertificate,
    this.createdByAdmin,
    this.yearPassedOut,
    required this.skills,
    required this.performanceScore,
    required this.totalAssignedTasks,
    required this.totalCompletedTasks,
    required this.totalPendingTasks,
    this.shiftStartTime = '09:00',
    this.shiftEndTime = '18:00',
  });

  StaffModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? mobileNumber,
    String? degree,
    String? role,
    String? category,
    String? branch,
    String? gender,
    String? nativePlace,
    String? joiningDate,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? profilePhoto,
    String? resume,
    String? aadhar,
    String? experience,
    String? previousCompany,
    String? bloodGroup,
    String? experienceCertificate,
    String? createdByAdmin,
    int? yearPassedOut,
    List<String>? skills,
    double? performanceScore,
    int? totalAssignedTasks,
    int? totalCompletedTasks,
    int? totalPendingTasks,
    String? shiftStartTime,
    String? shiftEndTime,
  }) {
    return StaffModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      degree: degree ?? this.degree,
      role: role ?? this.role,
      category: category ?? this.category,
      branch: branch ?? this.branch,
      gender: gender ?? this.gender,
      nativePlace: nativePlace ?? this.nativePlace,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      resume: resume ?? this.resume,
      aadhar: aadhar ?? this.aadhar,
      experience: experience ?? this.experience,
      previousCompany: previousCompany ?? this.previousCompany,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      experienceCertificate:
          experienceCertificate ?? this.experienceCertificate,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      yearPassedOut: yearPassedOut ?? this.yearPassedOut,
      skills: skills ?? this.skills,
      performanceScore: performanceScore ?? this.performanceScore,
      totalAssignedTasks: totalAssignedTasks ?? this.totalAssignedTasks,
      totalCompletedTasks: totalCompletedTasks ?? this.totalCompletedTasks,
      totalPendingTasks: totalPendingTasks ?? this.totalPendingTasks,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
    );
  }

  factory StaffModel.fromJson(Map<String, dynamic> j) {
    List<String> parseSkills(dynamic raw) {
      if (raw == null) return [];
      final str = raw.toString().trim();
      if (str.isEmpty) return [];
      return str
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    String parseStatus(dynamic active) {
      if (active == null) return 'ACTIVE';
      if (active is bool) return active ? 'ACTIVE' : 'INACTIVE';
      if (active is String) {
        return active.toLowerCase() == 'true' ? 'ACTIVE' : 'INACTIVE';
      }
      return 'ACTIVE';
    }

    String parseAdmin(dynamic admin) {
      if (admin == null) return '';
      if (admin is Map) return admin['name']?.toString() ?? admin['userName']?.toString() ?? admin['email']?.toString() ?? '';
      return admin.toString();
    }

    return StaffModel(
      id: j['id']?.toString() ?? '',
      employeeId: j['staffId'] ?? j['employeeId'] ?? '',
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      mobileNumber: j['mobileNumber'] ?? '',
      degree: j['degree'] ?? '',
      role: j['role'] ?? '',
      category: j['category'] ?? j['role'] ?? '',
      branch: j['branch'] ?? '',
      gender: j['gender']?.toString() ?? '',
      nativePlace: j['nativePlace']?.toString() ?? '',
      joiningDate: j['joiningDate']?.toString() ?? '',
      status: parseStatus(j['active']),
      createdAt: j['createdAt']?.toString() ?? '',
      updatedAt: j['updatedAt']?.toString(),
      profilePhoto: j['profilePhoto']?.toString(),
      resume: j['resumeFile']?.toString(),
      aadhar: j['aadhaarFile']?.toString(),
      experience: j['experience']?.toString(),
      previousCompany: j['previousCompany']?.toString(),
      bloodGroup: j['bloodGroup']?.toString(),
      experienceCertificate: j['experienceCertificate']?.toString(),
      createdByAdmin: parseAdmin(j['createdBy'] ?? j['createdByAdmin']),
      yearPassedOut: j['yearPassedOut'] as int?,
      skills: parseSkills(j['skills']),
      performanceScore: (j['score'] ?? 0).toDouble(),
      totalAssignedTasks: j['totalAssignedTasks'] ?? 0,
      totalCompletedTasks: j['totalCompletedTasks'] ?? 0,
      totalPendingTasks: j['totalPendingTasks'] ?? 0,
      shiftStartTime: (j['shiftStartTime']?.toString() ?? '').isNotEmpty
          ? j['shiftStartTime'].toString()
          : '09:00',
      shiftEndTime: (j['shiftEndTime']?.toString() ?? '').isNotEmpty
          ? j['shiftEndTime'].toString()
          : '18:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'mobileNumber': mobileNumber,
        'degree': degree,
        'role': role,
        'branch': branch,
        'skills': skills.join(', '),
        'active': status == 'ACTIVE',
        'joiningDate': joiningDate,
        'previousCompany': previousCompany ?? '',
        'bloodGroup': bloodGroup ?? '',
        'experience': experience != null ? int.tryParse(experience!) ?? 0 : 0,
      };
}
