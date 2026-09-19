class CertificateModel {
  final String id;
  final String studentId;
  final String studentName;
  final String collegeName;
  final String department;
  final String courseOrInternshipName;
  final String type;
  final String status;
  final String registrationDate;
  final String? updatedAt;
  final String? batchCode;
  final String? fileUrl;

  CertificateModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.collegeName = '',
    this.department = '',
    required this.courseOrInternshipName,
    required this.type,
    required this.status,
    required this.registrationDate,
    this.updatedAt,
    this.batchCode,
    this.fileUrl,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> j) {
    String safe(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      return v.toString();
    }

    // ✅ FIX: batchName is the actual human-readable name (e.g. "Full Stack Batch 2")
    // recordType is just "COURSE" or "INTERNSHIP" — used as the type badge, not the name
    // Fallback chain: batchName → courseName → internshipName → recordType (last resort)
    final name = safe(j['batchName']).isNotEmpty
        ? safe(j['batchName'])
        : safe(j['courseName']).isNotEmpty
            ? safe(j['courseName'])
            : safe(j['internshipName']).isNotEmpty
                ? safe(j['internshipName'])
                : safe(j['courseOrInternshipName']).isNotEmpty
                    ? safe(j['courseOrInternshipName'])
                    : 'Certificate'; // last resort — never show "COURSE" as name

    return CertificateModel(
      id: safe(j['id'] ?? j['_id'] ?? j['certificateId']),
      studentId: safe(j['studentId'] ?? j['student_code'] ?? j['studentCode']),
      studentName: safe(j['studentName']),
      collegeName: safe(j['collegeName']),
      department: safe(j['department']),
      courseOrInternshipName: name,
      // ✅ type is the badge label — "COURSE" or "INTERNSHIP"
      type: safe(j['recordType'] ?? j['type'] ?? 'COURSE'),
      status: safe(j['status'] ?? 'PENDING'),
      registrationDate: safe(
        j['registrationDate'] ?? j['issueDate'] ?? j['createdAt'] ?? '',
      ),
      updatedAt: safe(j['updatedAt']).isEmpty ? null : safe(j['updatedAt']),
      batchCode: safe(j['batchCode'] ?? j['batchName']).isEmpty
          ? null
          : safe(j['batchCode'] ?? j['batchName']),
      fileUrl: safe(j['fileUrl']).isEmpty ? null : safe(j['fileUrl']),
    );
  }
}
