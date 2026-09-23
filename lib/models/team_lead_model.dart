class TeamLeadModel {
  final String id;
  final String employeeId;
  final String fullName;
  final String email;
  final String phone;
  final String qualification;
  final String role;
  final String password;
  final String? profilePhoto;
  final String? resume;
  final String? aadhar;
  final String? experience;
  final String? previousWorkingCompany;
  final String? bloodGroup;
  final String? experienceCertificate;
  final String branchName;
  final List<String> skills;
  final String joiningDate;
  final String status;
  final String createdByAdmin;
  final double performanceScore;
  final int totalAssignedTasks;
  final int totalCompletedTasks;
  final int totalPendingTasks;
  final String createdAt;
  final String updatedAt;
  final String? gender;
  final String? dob;
  final String? nativePlace;
  final String? yearPassedOut;
  final String shiftStart;
  final String shiftEnd;

  TeamLeadModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.qualification,
    required this.role,
    required this.password,
    this.profilePhoto,
    this.resume,
    this.aadhar,
    this.experience,
    this.previousWorkingCompany,
    this.bloodGroup,
    this.experienceCertificate,
    required this.branchName,
    required this.skills,
    required this.joiningDate,
    required this.status,
    required this.createdByAdmin,
    required this.performanceScore,
    required this.totalAssignedTasks,
    required this.totalCompletedTasks,
    required this.totalPendingTasks,
    required this.createdAt,
    required this.updatedAt,
    this.gender,
    this.dob,
    this.nativePlace,
    this.yearPassedOut,
    this.shiftStart = '',
    this.shiftEnd = '',
  });

  factory TeamLeadModel.fromJson(Map<String, dynamic> j) {
    return TeamLeadModel(
      // Backend returns Long id — convert to String
      id: j['id']?.toString() ?? '',
      employeeId: j['teamLeadId']?.toString() ?? '',
      // Backend field is 'name' not 'fullName'
      fullName: j['name'] ?? '',
      email: j['email'] ?? '',
      // Backend field is 'mobileNumber' not 'phone'
      phone: j['mobileNumber'] ?? '',
      // Backend field is 'degree' not 'qualification'
      qualification: j['degree'] ?? '',
      role: j['role'] ?? j['degree'] ?? '',
      password: j['password'] ?? '',
      gender: j['gender'],
      dob: j['dob']?.toString(),
      nativePlace: j['nativePlace'],
      yearPassedOut: j['yearPassedOut']?.toString(),
      profilePhoto: j['profilePhoto'],
      resume: j['resumeFile'],
      aadhar: j['aadhaarFile'],
      experience: j['experience']?.toString(),
      previousWorkingCompany: j['previousCompany'],
      bloodGroup: j['bloodGroup'] ?? '',
      experienceCertificate: j['experienceCertificate'] ?? '',
      // Backend field is 'branch'
      branchName: j['branch'] ?? '',
      skills: _parseSkills(j['skills']),
      joiningDate: j['joiningDate']?.toString() ?? '',
      // Backend field is 'active' (Boolean) not 'status' (String)
      status: _parseStatus(j['active']),
      createdByAdmin: j['createdByAdmin']?.toString() ?? '',
      // Backend field is 'score' not 'performanceScore'
      performanceScore: (j['score'] ?? 0).toDouble(),
      totalAssignedTasks: j['totalAssignedTasks'] ?? 0,
      totalCompletedTasks: j['totalCompletedTasks'] ?? 0,
      totalPendingTasks: j['totalPendingTasks'] ?? 0,
      createdAt: j['createdAt']?.toString() ?? '',
      updatedAt: j['updatedAt']?.toString() ?? '',
      shiftStart: j['shiftStart']?.toString() ?? '',
      shiftEnd: j['shiftEnd']?.toString() ?? '',
    );
  }

  static List<String> _parseSkills(dynamic skills) {
    if (skills == null) return [];
    if (skills is List) {
      return skills
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (skills is String && skills.isNotEmpty) {
      return skills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  // Backend sends Boolean 'active', convert to String 'ACTIVE'/'INACTIVE'
  static String _parseStatus(dynamic active) {
    if (active == null) return 'ACTIVE';
    if (active is bool) return active ? 'ACTIVE' : 'INACTIVE';
    if (active is String) {
      if (active.toLowerCase() == 'true') return 'ACTIVE';
      if (active.toLowerCase() == 'false') return 'INACTIVE';
      return active.toUpperCase();
    }
    return 'ACTIVE';
  }

  Map<String, dynamic> toJson() => {
        'name': fullName,
        'email': email,
        'mobileNumber': phone,
        'degree': qualification,
        'role': role,
        'password': password,
        'experience': experience != null ? int.tryParse(experience!) : null,
        'previousCompany': previousWorkingCompany,
        'bloodGroup': bloodGroup,
        'branch': branchName,
        'skills': skills.join(', '),
        'active': status == 'ACTIVE',
        'score': performanceScore.toInt(),
        'gender': gender,
        'dob': dob,
        'nativePlace': nativePlace,
        'yearPassedOut': yearPassedOut != null ? int.tryParse(yearPassedOut!) : null,
      };

  TeamLeadModel copyWith({
    String? id,
    String? employeeId,
    String? fullName,
    String? email,
    String? phone,
    String? qualification,
    String? role,
    String? password,
    String? profilePhoto,
    String? resume,
    String? aadhar,
    String? experience,
    String? previousWorkingCompany,
    String? bloodGroup,
    String? experienceCertificate,
    String? branchName,
    List<String>? skills,
    String? joiningDate,
    String? status,
    String? createdByAdmin,
    double? performanceScore,
    int? totalAssignedTasks,
    int? totalCompletedTasks,
    int? totalPendingTasks,
    String? createdAt,
    String? updatedAt,
    String? gender,
    String? dob,
    String? nativePlace,
    String? yearPassedOut,
  }) {
    return TeamLeadModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualification: qualification ?? this.qualification,
      role: role ?? this.role,
      password: password ?? this.password,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      resume: resume ?? this.resume,
      aadhar: aadhar ?? this.aadhar,
      experience: experience ?? this.experience,
      previousWorkingCompany:
          previousWorkingCompany ?? this.previousWorkingCompany,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      experienceCertificate:
          experienceCertificate ?? this.experienceCertificate,
      branchName: branchName ?? this.branchName,
      skills: skills ?? this.skills,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      performanceScore: performanceScore ?? this.performanceScore,
      totalAssignedTasks: totalAssignedTasks ?? this.totalAssignedTasks,
      totalCompletedTasks: totalCompletedTasks ?? this.totalCompletedTasks,
      totalPendingTasks: totalPendingTasks ?? this.totalPendingTasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      nativePlace: nativePlace ?? this.nativePlace,
      yearPassedOut: yearPassedOut ?? this.yearPassedOut,
    );
  }
}
