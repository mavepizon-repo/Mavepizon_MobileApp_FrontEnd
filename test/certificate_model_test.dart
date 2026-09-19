import 'package:flutter_test/flutter_test.dart';
import 'package:mavepizon/models/certificate_model.dart';

void main() {
  group('CertificateModel backend contract', () {
    test('maps certificate DTO fields from backend response', () {
      final model = CertificateModel.fromJson({
        'certificateId': 42,
        'studentId': 7,
        'studentName': 'Ravi Kumar',
        'studentCode': 'STU-007',
        'recordType': 'COURSE',
        'batchName': 'Java Batch',
        'status': 'PENDING',
        'fileUrl': 'https://cdn.example/cert.pdf',
        'issueDate': '2025-05-20',
      });

      expect(model.id, '42');
      expect(model.studentId, '7');
      expect(model.studentName, 'Ravi Kumar');
      expect(model.courseOrInternshipName, 'Java Batch');
      expect(model.type, 'COURSE');
      expect(model.status, 'PENDING');
      expect(model.registrationDate, '2025-05-20');
    });
  });
}
