import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/backup_service.dart';
import 'package:plop/core/services/database_service.dart';

import 'backup_service_test.mocks.dart';

@GenerateMocks([DatabaseService, Box])
void main() {
  late BackupService backupService;
  late MockDatabaseService mockDatabaseService;
  late MockBox<Contact> mockContactsBox;
  late MockBox<MessageModel> mockMessagesBox;
  late MockBox<dynamic> mockSettingsBox;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    mockContactsBox = MockBox<Contact>();
    mockMessagesBox = MockBox<MessageModel>();
    mockSettingsBox = MockBox<dynamic>();
    backupService = BackupService(mockDatabaseService);

    when(mockDatabaseService.contactsBox).thenReturn(mockContactsBox);
    when(mockDatabaseService.messagesBox).thenReturn(mockMessagesBox);
    when(mockDatabaseService.settingsBox).thenReturn(mockSettingsBox);
  });

  group('BackupService', () {
    test('importBackup correctly processes a JSON string', () async {
      // Arrange
      final contact = Contact(
        userId: '2',
        originalPseudo: 'imported',
        alias: 'Imported',
        colorValue: 1,
      );
      final jsonString = jsonEncode({
        'contacts': [contact.toJson()],
        'messages': [],
        'contactsOrder': [],
      });

      when(mockContactsBox.clear()).thenAnswer((_) async => 0);
      when(mockMessagesBox.clear()).thenAnswer((_) async => 0);
      when(mockSettingsBox.put(any, any)).thenAnswer((_) async {});
      when(mockContactsBox.put(any, any)).thenAnswer((_) async {});

      // Act
      final result = await backupService.importBackup(jsonString);

      // Assert
      expect(result, isTrue);
      verify(mockContactsBox.clear()).called(1);
      verify(mockMessagesBox.clear()).called(1);
      verify(mockContactsBox.put(
        equals('2'),
        argThat(isA<Contact?>()
            .having((c) => c!.originalPseudo, 'originalPseudo', 'imported')),
      )).called(1);
    });
  });
}
