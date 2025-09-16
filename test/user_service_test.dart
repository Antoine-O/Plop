import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service_test.mocks.dart';

// Since we can't run build_runner, we'll create a simple fake
// that implements the DatabaseService interface.
class FakeDatabaseService implements DatabaseService {
  @override
  Future<void> addContact(Contact contact) async {}

  @override
  Future<void> addMessage(MessageModel message) async {}

  @override
  Future<void> clearContacts() async {}

  @override
  Future<void> clearMessages() async {}

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([http.Client])
void main() {
  group('UserService', () {
    late UserService userService;
    late MockClient mockClient;
    late FakeDatabaseService fakeDatabaseService;

    setUp(() async {
      mockClient = MockClient();
      fakeDatabaseService = FakeDatabaseService();
      userService = UserService.internal(fakeDatabaseService, mockClient);
      SharedPreferences.setMockInitialValues({});
      await userService.init();
    });

    test('createUser success', () async {
      when(mockClient.post(Uri.parse('http://localhost:8080/users/generate-id')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'userId': 'test-uuid'}), 200));

      final result = await userService.createUser('testuser');

      expect(result, true);
      expect(userService.userId, 'test-uuid');
      expect(userService.username, 'testuser');
    });

    test('createUser failure', () async {
      when(mockClient.post(Uri.parse('http://localhost:8080/users/generate-id')))
          .thenAnswer((_) async => http.Response('Server error', 500));

      final result = await userService.createUser('testuser');

      expect(result, false);
      expect(userService.userId, null);
      // The username is set before the API call, so it will be 'testuser'.
      // Depending on desired behavior, you might want to clear it on failure.
      // For now, testing the state as it is implemented.
      expect(userService.username, 'testuser');
    });
  });
}
