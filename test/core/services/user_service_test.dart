import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service_test.mocks.dart';

@GenerateMocks([SharedPreferences, DatabaseService, http.Client])
void main() {
  group('UserService', () {
    late UserService userService;
    late MockSharedPreferences mockPrefs;
    late MockDatabaseService mockDatabaseService;
    late MockClient mockClient;

    setUp(() async {
      mockPrefs = MockSharedPreferences();
      mockDatabaseService = MockDatabaseService();
      mockClient = MockClient();
      userService = UserService.internal(mockDatabaseService, mockClient);

      when(mockPrefs.getString('userId')).thenReturn(null);
      when(mockPrefs.getString('username')).thenReturn(null);
      when(mockPrefs.getBool('globalMute')).thenReturn(false);
      await userService.init(prefs: mockPrefs);
    });

    test('hasUser returns false when no user is set', () {
      expect(userService.hasUser(), isFalse);
    });

    test('createUser successfully creates a user', () async {
      when(mockClient.post(any))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'userId': '123'}), 200));

      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      final result =
          await userService.createUser('testuser');

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

      await userService.updateUsername('newuser', prefs: mockPrefs);

      expect(userService.username, 'newuser');
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setString('username', 'newuser')).called(1);
    });

    test('toggleGlobalMute toggles the mute state', () async {
      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      await userService.toggleGlobalMute(prefs: mockPrefs);

      expect(userService.isGlobalMute, isTrue);
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setBool('globalMute', true)).called(1);

      await userService.toggleGlobalMute(prefs: mockPrefs);
      expect(userService.isGlobalMute, isFalse);
      verify(mockPrefs.setBool('globalMute', false)).called(1);
    });

    test('syncContactsPseudos updates contacts with new pseudos', () async {
      final contacts = [
        Contact(userId: '1', originalPseudo: 'old', alias: 'a', colorValue: 1)
      ];
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'1': 'new'}), 200));

      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      final result =
          await userService.syncContactsPseudos(contacts);

      expect(result, isTrue);
      expect(contacts.first.originalPseudo, 'new');
      expect(listenerCalled, isTrue);
      verify(mockDatabaseService.updateContact(any)).called(1);
    });
  });
}
