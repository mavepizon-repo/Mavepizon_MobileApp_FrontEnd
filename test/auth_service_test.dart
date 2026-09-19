import 'package:flutter_test/flutter_test.dart';
import 'package:mavepizon/services/auth_service.dart';

void main() {
  group('AuthService login payload normalization', () {
    test('maps team lead login response from backend fields', () {
      final normalized = AuthService.normalizeLoginPayload(
        {
          'token': 'abc123',
          'teamLeadId': '42',
          'email': 'lead@example.com',
          'message': 'Login Successful',
        },
        'TEAM_LEAD',
      );

      expect(normalized['token'], 'abc123');
      expect(normalized['role'], 'TEAM_LEAD');
      expect(normalized['userId'], '42');
      expect(normalized['email'], 'lead@example.com');
      expect(normalized['name'], 'lead');
    });

    test('falls back to alternate backend field names', () {
      final normalized = AuthService.normalizeLoginPayload(
        {
          'token': 'xyz789',
          'userId': '7',
          'fullName': 'Team Lead',
          'email': 'teamlead@example.com',
        },
        'TEAM_LEAD',
      );

      expect(normalized['token'], 'xyz789');
      expect(normalized['role'], 'TEAM_LEAD');
      expect(normalized['userId'], '7');
      expect(normalized['email'], 'teamlead@example.com');
      expect(normalized['name'], 'Team Lead');
    });
  });
}
