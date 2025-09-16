import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:plop/core/services/backup_service.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service_test.mocks.dart';

@GenerateMocks([UserService, DatabaseService, FilePicker, SharedPreferences])
void main() {
  group('BackupService', () {
    late BackupService backupService;
    late MockUserService mockUserService;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      backupService = BackupService();
      mockUserService = MockUserService();
      mockDatabaseService = MockDatabaseService();
    });

    group('saveBackup', () {
      test('should return null on successful backup to user selected location',
          () async {
        when(mockUserService.username).thenReturn('testuser');
        when(mockUserService.userId).thenReturn('123');
        when(mockDatabaseService.getAllMessages()).thenReturn([]);
        when(mockDatabaseService.getAllContactsOrdered())
            .thenAnswer((_) async => []);
        when(mockDatabaseService.getContactsOrder())
            .thenAnswer((_) async => []);

        final result = await backupService.saveBackup(
          userService: mockUserService,
          databaseService: mockDatabaseService,
          saveToUserSelectedLocation: true,
        );

        expect(result, isNull);
      });

      test('should return null on successful backup to internal directory',
          () async {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(directory.path, 'plop_config_backup.json');
        final file = File(filePath);

        when(mockUserService.username).thenReturn('testuser');
        when(mockUserService.userId).thenReturn('123');
        when(mockDatabaseService.getAllMessages()).thenReturn([]);
        when(mockDatabaseService.getAllContactsOrdered())
            .thenAnswer((_) async => []);
        when(mockDatabaseService.getContactsOrder())
            .thenAnswer((_) async => []);

        final result = await backupService.saveBackup(
          userService: mockUserService,
          databaseService: mockDatabaseService,
          saveToUserSelectedLocation: false,
        );

        expect(result, isNull);
        expect(await file.exists(), isTrue);

        await file.delete();
      });

      test('should return error message when user data is not available',
          () async {
        when(mockUserService.username).thenReturn(null);
        when(mockUserService.userId).thenReturn(null);

        final result = await backupService.saveBackup(
          userService: mockUserService,
          databaseService: mockDatabaseService,
        );

        expect(result, 'Les données utilisateur ne sont pas disponibles.');
      });
    });

    group('restoreFromBackup', () {
      test('should return null on successful restore', () async {
        final now = DateTime.now();
        final backupData = {
          'userId': '123',
          'username': 'testuser',
          'messages': [
            {'id': '1', 'text': 'Hello'}
          ],
          'contacts': [
            {
              'userId': '456',
              'originalPseudo': 'John Doe',
              'alias': 'Johnny',
              'colorValue': 4282339839,
              'isMuted': false,
              'type': 'user',
              'lastMessage': 'Hi',
              'lastMessageTimestamp': now.toIso8601String(),
              'isBlocked': false,
              'customSoundPath': null,
              'defaultMessageOverride': null,
              'isHidden': false,
              'lastMessageSentTimestamp': now.toIso8601String(),
              'lastMessageSent': 'Hi',
              'lastMessageSentDefault': true,
              'lastMessageSentStatus': 'sent',
              'lastMessageSentError': null,
            }
          ],
          'contactsOrder': ['456'],
        };
        final jsonString = jsonEncode(backupData);
        final fileBytes = utf8.encode(jsonString);

        final mockFilePicker = MockFilePicker();
        when(mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        )).thenAnswer((_) async => FilePickerResult([
              PlatformFile(
                name: 'plop_config_backup.json',
                bytes: fileBytes,
                size: fileBytes.length,
              ),
            ]));

        final mockSharedPreferences = MockSharedPreferences();
        when(mockSharedPreferences.setString('userId', '123'))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.setString('username', 'testuser'))
            .thenAnswer((_) async => true);

        final result = await backupService.restoreFromBackup();

        expect(result, isNull);
      });

      test('should return error message on file selection cancelled', () async {
        final mockFilePicker = MockFilePicker();
        when(mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        )).thenAnswer((_) async => null);

        final result = await backupService.restoreFromBackup();

        expect(result, 'Sélection de fichier annulée.');
      });

      test('should return error message on invalid backup file', () async {
        final backupData = {'invalid_key': 'invalid_value'};
        final jsonString = jsonEncode(backupData);
        final fileBytes = utf8.encode(jsonString);

        final mockFilePicker = MockFilePicker();
        when(mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        )).thenAnswer((_) async => FilePickerResult([
              PlatformFile(
                name: 'plop_config_backup.json',
                bytes: fileBytes,
                size: fileBytes.length,
              ),
            ]));

        final result = await backupService.restoreFromBackup();

        expect(result, 'Fichier de sauvegarde invalide ou corrompu.');
      });
    });
  });
}
