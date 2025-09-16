import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/websocket_service.dart';

import 'user_service_test.mocks.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockClient mockClient;
    late MockWebSocketService mockWebSocketService;

    setUp(() {
      mockClient = MockClient();
      mockWebSocketService = MockWebSocketService();
      syncService = SyncService(client: mockClient, webSocketService: mockWebSocketService);
    });

    test('createSyncCode returns a code on success', () async {
      final userId = 'test-user-id';
      final url = Uri.parse('http://localhost:8080/sync/create?userId=$userId');
      final response = {'code': 'test-code'};

      when(mockClient.get(url)).thenAnswer((_) async => http.Response(jsonEncode(response), 200));

      final result = await syncService.createSyncCode(userId);

      expect(result, equals('test-code'));
    });

    test('useSyncCode returns user data on success', () async {
      final code = 'test-code';
      final url = Uri.parse('http://localhost:8080/sync/use');
      final requestBody = jsonEncode({'code': code});
      final response = {'userId': 'other-user-id', 'pseudo': 'other-user-pseudo'};

      when(mockClient.post(url, headers: {'Content-Type': 'application/json'}, body: requestBody))
          .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

      final result = await syncService.useSyncCode(code);

      expect(result, equals(response));
    });
  });
}
