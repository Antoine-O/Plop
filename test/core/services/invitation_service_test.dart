import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/invitation_service.dart';

import 'invitation_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  setUpAll(() async {
    await dotenv.load();
  });
  group('InvitationService', () {
    late InvitationService invitationService;
    late MockClient mockClient;

    setUp(() {
      invitationService = InvitationService();
      mockClient = MockClient();
    });

    group('createInvitationCode', () {
      test('should return invitation code on successful request', () async {
        final json = {'code': '123456', 'validityMinutes': 15};
        when(mockClient.post(any))
            .thenAnswer((_) async => http.Response(jsonEncode(json), 200));

        final result = await invitationService.createInvitationCode(
          'user1',
          'pseudo1',
          client: mockClient,
        );

        expect(result, {'code': '123456', 'validityMinutes': 15});
      });

      test('should return null on failed request', () async {
        when(mockClient.post(any))
            .thenAnswer((_) async => http.Response('Error', 404));

        final result = await invitationService.createInvitationCode(
          'user1',
          'pseudo1',
          client: mockClient,
        );

        expect(result, isNull);
      });
    });

    group('useInvitationCode', () {
      test('should return user data on successful request', () async {
        final json = {'userId': 'user2', 'pseudo': 'pseudo2'};
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(jsonEncode(json), 200));

        final result = await invitationService.useInvitationCode(
          '123456',
          'user1',
          'pseudo1',
          client: mockClient,
        );

        expect(result, {'userId': 'user2', 'pseudo': 'pseudo2'});
      });

      test('should return null on failed request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('Error', 404));

        final result = await invitationService.useInvitationCode(
          '123456',
          'user1',
          'pseudo1',
          client: mockClient,
        );

        expect(result, isNull);
      });
    });
  });
}
