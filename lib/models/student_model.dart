class StudentModel {
  final String id,
      studentId,
      fullName,
      email,
      phone,
      collegeName,
      department,
      registrationDate;
  final String? paymentStatus, certificateStatus, batchCode;

  StudentModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.collegeName,
    required this.department,
    required this.registrationDate,
    this.paymentStatus,
    this.certificateStatus,
    this.batchCode,
  });

  factory StudentModel.fromJson(Map<String, dynamic> j) => StudentModel(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        studentId: j['studentId'] ?? '',
        fullName: j['name'] ?? j['fullName'] ?? '',
        email: j['email'] ?? '',
        phone: j['mobileNumber'] ?? j['phone'] ?? '',
        collegeName: j['collegeName'] ?? '',
        department: j['department'] ?? '',
        registrationDate: j['registrationDate'] ?? '',
        paymentStatus: j['paymentStatus'],
        certificateStatus: j['certificateStatus'],
        batchCode: j['batchCode'],
      );
}
