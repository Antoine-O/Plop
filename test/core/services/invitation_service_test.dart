
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plop/core/services/invitation_service.dart';

void main() {
  group('InvitationService', () {
    late InvitationService invitationService;

    setUp(() {
      invitationService = InvitationService();
    });

    group('createInvitationCode', () {
      test('should return invitation code on successful request', () async {
        final mockClient = MockClient((request) async {
          final json = {'code': '123456', 'validityMinutes': 15};
          return http.Response(jsonEncode(json), 200);
        });

        final result = await invitationService.createInvitationCode('user1', 'pseudo1');

        expect(result, {'code': '123456', 'validityMinutes': 15});
      });

      test('should return null on failed request', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 404);
        });

        final result = await invitationService.createInvitationCode('user1', 'pseudo1');

        expect(result, isNull);
      });
    });

    group('useInvitationCode', () {
      test('should return user data on successful request', () async {
        final mockClient = MockClient((request) async {
          final json = {'userId': 'user2', 'pseudo': 'pseudo2'};
          return http.Response(jsonEncode(json), 200);
        });

        final result = await invitationService.useInvitationCode('123456', 'user1', 'pseudo1');

        expect(result, {'userId': 'user2', 'pseudo': 'pseudo2'});
      });

      test('should return null on failed request', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 404);
        });

        final result = await invitationService.useInvitationCode('123456', 'user1', 'pseudo1');

        expect(result, isNull);
      });
    });
  });
}
