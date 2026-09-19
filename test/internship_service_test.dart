import 'package:flutter_test/flutter_test.dart';
import 'package:mavepizon/models/internship_model.dart';

void main() {
  test('maps backend Course JSON keys onto InternshipModel properties', () {
    final internship = InternshipModel.fromJson({
      'id': 101,
      'courseName': 'Full-Stack Internship',
      'courseCode': 'INT001',
      'batchId': 'B2026-01',
      'category': 'INTERNSHIP',
      'description': 'Web dev internship',
      'duration': '8 WEEKS',
      'startDate': '2026-09-01',
      'endDate': '2026-10-31',
      'registrationStartDate': '2026-08-10',
      'registrationEndDate': '2026-08-30',
      'totalFees': 5000,
      'registrationFees': 500,
      'totalSeatsOnline': 20,
      'registeredSeatsOnline': 2,
      'availableSeatsOnline': 18,
      'totalSeatsOffline': 10,
      'registeredSeatsOffline': 1,
      'availableSeatsOffline': 9,
      'totalSeatsTirunelveli': 6,
      'availableSeatsTirunelveli': 5,
      'totalSeatsTisaiyanvilai': 4,
      'availableSeatsTisaiyanvilai': 4,
      'status': 'ACTIVE',
      'createdBy': 'Admin (Admin)',
      'zoomLink': 'https://zoom.us/j/123',
    });

    expect(internship.id, '101');
    expect(internship.internshipName, 'Full-Stack Internship');
    expect(internship.internshipCode, 'INT001');
    expect(internship.batchCode, 'B2026-01');
    expect(internship.category, 'INTERNSHIP');
    expect(internship.status, 'ACTIVE');
    expect(internship.trainerName, 'Admin (Admin)');
    expect(internship.fees, 5000);
    expect(internship.registrationFees, 500);
    expect(internship.registrationStartDate, '2026-08-10');
    expect(internship.registrationEndDate, '2026-08-30');
    expect(internship.totalSeatsOnline, 20);
    expect(internship.availableSeatsOnline, 18);
    expect(internship.totalSeatsOffline, 10);
    expect(internship.totalSeatsTirunelveli, 6);
    expect(internship.totalSeatsTisaiyanvilai, 4);
    expect(internship.zoomLink, 'https://zoom.us/j/123');
    expect(internship.active, true);
  });

  test('falls back gracefully when required keys are missing', () {
    final internship = InternshipModel.fromJson({'id': 1, 'status': 'INACTIVE'});

    expect(internship.internshipName, '');
    expect(internship.internshipCode, '');
    expect(internship.fees, 0);
    expect(internship.totalSeatsOnline, 0);
    expect(internship.availableSeatsOffline, 0);
    expect(internship.active, false);
  });
}