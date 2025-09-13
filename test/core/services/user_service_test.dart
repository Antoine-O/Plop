
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('UserService', () {
    late UserService userService;
    late MockSharedPreferences mockPrefs;
    late MockDatabaseService mockDatabaseService;

    setUp(() async {
      mockPrefs = MockSharedPreferences();
      mockDatabaseService = MockDatabaseService();
      userService = UserService();
      
      // You need to ensure the `_prefs` field in UserService is set to your mock.
      // This might require a change in UserService to allow injection, or you can use
      // a testing setup that allows you to replace it. For this example, we assume it's possible.
      when(mockPrefs.getString('userId')).thenReturn(null);
      when(mockPrefs.getString('username')).thenReturn(null);
      when(mockPrefs.getBool('globalMute')).thenReturn(false);
      await userService.init();
    });

    test('hasUser returns false when no user is set', () {
      expect(userService.hasUser(), isFalse);
    });

    test('createUser successfully creates a user', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'userId': '123'}), 200);
      });
      // This is tricky without dependency injection for http.Client.
      // Assume for the test we can influence the http call.
      
      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      final result = await userService.createUser('testuser');

      expect(result, isTrue);
      expect(userService.userId, '123');
      expect(userService.username, 'testuser');
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setString('userId', '123')).called(1);
      verify(mockPrefs.setString('username', 'testuser')).called(1);
    });

    test('updateUsername updates the username', () async {
      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      await userService.updateUsername('newuser');

      expect(userService.username, 'newuser');
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setString('username', 'newuser')).called(1);
    });

    test('toggleGlobalMute toggles the mute state', () async {
      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);
      
      await userService.toggleGlobalMute();

      expect(userService.isGlobalMute, isTrue);
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setBool('globalMute', true)).called(1);

      await userService.toggleGlobalMute();
      expect(userService.isGlobalMute, isFalse);
      verify(mockPrefs.setBool('globalMute', false)).called(1);
    });

    test('syncContactsPseudos updates contacts with new pseudos', () async {
      final contacts = [Contact(userId: '1', originalPseudo: 'old', alias: 'a', colorValue: 1)];
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'1': 'new'}), 200);
      });

      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      final result = await userService.syncContactsPseudos(contacts);

      expect(result, isTrue);
      expect(contacts.first.originalPseudo, 'new');
      expect(listenerCalled, isTrue);
      verify(mockDatabaseService.updateContact(any)).called(1);
    });
  });
}
