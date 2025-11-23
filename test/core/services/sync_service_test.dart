import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'dart:convert';

import 'sync_service_test.mocks.dart';

@GenerateMocks([WebSocketService, http.Client])
void main() {
  late SyncService syncService;
  late MockWebSocketService mockWebSocketService;
  late MockClient mockHttpClient;

  setUp(() {
    mockWebSocketService = MockWebSocketService();
    mockHttpClient = MockClient();
    syncService = SyncService(
      mockWebSocketService,
      baseUrl: 'http://localhost:3000', // Dummy URL for testing
    );
  });

  group('SyncService', () {
    group('createSyncCode', () {
      test('returns sync code on successful API call', () async {
        // Arrange
        final userId = 'testUser';
        final expectedCode = 'testCode';
        final responsePayload = {'code': expectedCode};
        when(mockWebSocketService.connect()).thenAnswer((_) async {});
        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(
              jsonEncode(responsePayload),
              200,
            ));

        // Act
        final result =
            await syncService.createSyncCode(userId, client: mockHttpClient);

        // Assert
        expect(result, expectedCode);
        verify(mockWebSocketService.connect()).called(1);
      });

      test('returns null on failed API call', () async {
        // Arrange
        final userId = 'testUser';
        when(mockWebSocketService.connect()).thenAnswer((_) async {});
        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(
              'Error',
              500,
            ));

        // Act
        final result =
            await syncService.createSyncCode(userId, client: mockHttpClient);

        // Assert
        expect(result, isNull);
      });
    });

    group('useSyncCode', () {
      test('returns user data on successful API call', () async {
        // Arrange
        final code = 'testCode';
        final expectedUserId = 'testUser';
        final expectedPseudo = 'testPseudo';
        final responsePayload = {
          'userId': expectedUserId,
          'pseudo': expectedPseudo,
        };
        when(mockWebSocketService.connect()).thenAnswer((_) async {});
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                  jsonEncode(responsePayload),
                  200,
                ));

        // Act
        final result = await syncService.useSyncCode(code, client: mockHttpClient);

        // Assert
        expect(result, {'userId': expectedUserId, 'pseudo': expectedPseudo});
        verify(mockWebSocketService.connect()).called(1);
      });

      test('returns null on failed API call', () async {
        // Arrange
        final code = 'testCode';
        when(mockWebSocketService.connect()).thenAnswer((_) async {});
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                  'Error',
                  500,
                ));

        // Act
        final result = await syncService.useSyncCode(code, client: mockHttpClient);

        // Assert
        expect(result, isNull);
      });
    });
  });
}
