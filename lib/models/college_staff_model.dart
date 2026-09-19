class CollegeStaffModel {
  final String id;
  final String name;
  final String collegeName;
  final String department;
  final String email;
  final String mobileNumber;
  final String gender;
  final int uploadedStudentsCount;
  final String createdAt;

  CollegeStaffModel({
    required this.id,
    required this.name,
    required this.collegeName,
    required this.department,
    required this.email,
    required this.mobileNumber,
    required this.gender,
    required this.uploadedStudentsCount,
    this.createdAt = '',
  });

  factory CollegeStaffModel.fromJson(Map<String, dynamic> j) {
    return CollegeStaffModel(
      id: j['collegeStaffId']?.toString() ?? j['id']?.toString() ?? '',
      name: j['name'] ?? '',
      collegeName: j['collegeName'] ?? '',
      department: j['department'] ?? '',
      email: j['email'] ?? '',
      mobileNumber: j['mobileNumber'] ?? '',
      gender: j['gender'] ?? '',
      uploadedStudentsCount: j['uploadedStudentsCount'] ?? 0,
      createdAt: j['createdAt']?.toString() ?? '',
    );
  }
}
