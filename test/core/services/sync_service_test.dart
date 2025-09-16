import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/websocket_service.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([http.Client, WebSocketService])
void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockWebSocketService mockWebSocketService;
    late MockClient mockClient;

    setUp(() {
      syncService = SyncService();
      mockWebSocketService = MockWebSocketService();
      mockClient = MockClient();
    });

    group('createSyncCode', () {
      test('should return sync code on successful request', () async {
        final json = {'code': '123456'};
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(jsonEncode(json), 200));

        final result = await syncService.createSyncCode('user1',
            client: mockClient, webSocketService: mockWebSocketService);

        expect(result, '123456');
        verify(mockWebSocketService.ensureConnected()).called(1);
      });

      test('should return null on failed request', () async {
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('Error', 404));

        final result = await syncService.createSyncCode('user1',
            client: mockClient, webSocketService: mockWebSocketService);

        expect(result, isNull);
        verify(mockWebSocketService.ensureConnected()).called(1);
      });
    });

    group('useSyncCode', () {
      test('should return user data on successful request', () async {
        final json = {'userId': 'user2', 'pseudo': 'pseudo2'};
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(jsonEncode(json), 200));

        final result = await syncService.useSyncCode('123456',
            client: mockClient, webSocketService: mockWebSocketService);

        expect(result, {'userId': 'user2', 'pseudo': 'pseudo2'});
        verify(mockWebSocketService.ensureConnected()).called(1);
      });

      test('should return null on failed request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('Error', 404));

        final result = await syncService.useSyncCode('123456',
            client: mockClient, webSocketService: mockWebSocketService);

        expect(result, isNull);
        verify(mockWebSocketService.ensureConnected()).called(1);
      });
    });
  });
}
