import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/services/user_service.dart';
import 'dart:convert';

import 'package:mockito/annotations.dart';

import 'user_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('UserService', () {
    late UserService userService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      userService = UserService();
      SharedPreferences.setMockInitialValues({});
    });

    test('createUser success', () async {
      when(mockClient.get(Uri.parse('http://localhost:8080/users/generate-id')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'userId': 'test-uuid'}), 200));

      final result = await userService.createUser('testuser');

      expect(result, true);
      expect(userService.userId, 'test-uuid');
      expect(userService.username, 'testuser');
    });

    test('createUser failure', () async {
      when(mockClient.get(Uri.parse('http://localhost:8080/users/generate-id')))
          .thenAnswer((_) async => http.Response('Server error', 500));

      final result = await userService.createUser('testuser');

      expect(result, false);
      expect(userService.userId, null);
      expect(userService.username, null);
    });
  });
}
