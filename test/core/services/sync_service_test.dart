
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/websocket_service.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockWebSocketService mockWebSocketService;

    setUp(() {
      syncService = SyncService();
      mockWebSocketService = MockWebSocketService();
      // You'll need to inject this mock into your SyncService.
      // For this example, we assume it's possible.
    });

    group('createSyncCode', () {
      test('should return sync code on successful request', () async {
        final mockClient = MockClient((request) async {
          final json = {'code': '123456'};
          return http.Response(jsonEncode(json), 200);
        });

        final result = await syncService.createSyncCode('user1');

        expect(result, '123456');
        verify(mockWebSocketService.ensureConnected()).called(1);
      });

      test('should return null on failed request', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 404);
        });

        final result = await syncService.createSyncCode('user1');

        expect(result, isNull);
        verify(mockWebSocketService.ensureConnected()).called(1);
      });
    });

    group('useSyncCode', () {
      test('should return user data on successful request', () async {
        final mockClient = MockClient((request) async {
          final json = {'userId': 'user2', 'pseudo': 'pseudo2'};
          return http.Response(jsonEncode(json), 200);
        });

        final result = await syncService.useSyncCode('123456');

        expect(result, {'userId': 'user2', 'pseudo': 'pseudo2'});
        verify(mockWebSocketService.ensureConnected()).called(1);
      });

      test('should return null on failed request', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 404);
        });

        final result = await syncService.useSyncCode('123456');

        expect(result, isNull);
        verify(mockWebSocketService.ensureConnected()).called(1);
      });
    });
  });
}
