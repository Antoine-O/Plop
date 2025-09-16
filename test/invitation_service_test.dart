import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/services/invitation_service.dart';
import 'dart:convert';

import 'user_service_test.mocks.dart';

void main() {
  group('InvitationService', () {
    late InvitationService invitationService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      invitationService = InvitationService(client: mockClient);
    });

    group('createInvitationCode', () {
      test('returns a map with code and validityMinutes on success', () async {
        final userId = 'test-user-id';
        final userPseudo = 'test-user-pseudo';
        final url = Uri.parse('http://localhost:8080/invitations/create?userId=$userId&pseudo=$userPseudo');
        final response = {
          'code': 'test-code',
          'validityMinutes': 10,
        };

        when(mockClient.get(url)).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

        final result = await invitationService.createInvitationCode(userId, userPseudo);

        expect(result, equals(response));
      });

      test('returns null on failure', () async {
        final userId = 'test-user-id';
        final userPseudo = 'test-user-pseudo';
        final url = Uri.parse('http://localhost:8080/invitations/create?userId=$userId&pseudo=$userPseudo');

        when(mockClient.get(url)).thenAnswer((_) async => http.Response('Error', 500));

        final result = await invitationService.createInvitationCode(userId, userPseudo);

        expect(result, isNull);
      });
    });

    group('useInvitationCode', () {
      test('returns a map with userId and pseudo on success', () async {
        final code = 'test-code';
        final myUserId = 'my-user-id';
        final myPseudo = 'my-user-pseudo';
        final url = Uri.parse('http://localhost:8080/invitations/use');
        final requestBody = jsonEncode({
          'code': code,
          'userId': myUserId,
          'pseudo': myPseudo,
        });
        final response = {
          'userId': 'other-user-id',
          'pseudo': 'other-user-pseudo',
        };

        when(mockClient.post(url, headers: {'Content-Type': 'application/json'}, body: requestBody))
            .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

        final result = await invitationService.useInvitationCode(code, myUserId, myPseudo);

        expect(result, equals(response));
      });

      test('returns null on failure', () async {
        final code = 'test-code';
        final myUserId = 'my-user-id';
        final myPseudo = 'my-user-pseudo';
        final url = Uri.parse('http://localhost:8080/invitations/use');
        final requestBody = jsonEncode({
          'code': code,
          'userId': myUserId,
          'pseudo': myPseudo,
        });

        when(mockClient.post(url, headers: {'Content-Type': 'application/json'}, body: requestBody))
            .thenAnswer((_) async => http.Response('Error', 500));

        final result = await invitationService.useInvitationCode(code, myUserId, myPseudo);

        expect(result, isNull);
      });
    });
  });
}
