import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service_test.mocks.dart';

@GenerateMocks([SharedPreferences, DatabaseService, http.Client, Box])
void main() {
  setUpAll(() async {
    await dotenv.load();
  });
  group('UserService', () {
    late UserService userService;
    late MockSharedPreferences mockPrefs;
    late MockDatabaseService mockDatabaseService;
    late MockClient mockClient;
    late MockBox<Contact> mockContactsBox;

    setUp(() async {
      mockPrefs = MockSharedPreferences();
      mockDatabaseService = MockDatabaseService();
      mockClient = MockClient();
      mockContactsBox = MockBox<Contact>();
      userService = UserService.internal(mockDatabaseService, mockClient);

      when(mockDatabaseService.contactsBox).thenReturn(mockContactsBox);
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
      when(mockPrefs.setString('userId', any)).thenAnswer((_) async => true);
      when(mockPrefs.setString('username', any)).thenAnswer((_) async => true);

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
      when(mockPrefs.setString('username', 'newuser'))
          .thenAnswer((_) async => true);
      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      await userService.updateUsername('newuser', prefs: mockPrefs);

      expect(userService.username, 'newuser');
      expect(listenerCalled, isTrue);
      verify(mockPrefs.setString('username', 'newuser')).called(1);
    });

    test('toggleGlobalMute toggles the mute state', () async {
      when(mockPrefs.setBool('globalMute', any)).thenAnswer((_) async => true);
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
      when(mockContactsBox.put(any, any)).thenAnswer((_) async => Future.value());

      var listenerCalled = false;
      userService.addListener(() => listenerCalled = true);

      final result =
          await userService.syncContactsPseudos(contacts);

      expect(result, isTrue);
      expect(contacts.first.originalPseudo, 'new');
      expect(listenerCalled, isTrue);
      verify(mockContactsBox.put('1', contacts.first)).called(1);
    });
  });
}
