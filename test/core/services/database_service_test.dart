import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';

import 'database_service_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  late DatabaseService databaseService;
  late MockBox<Contact> mockContactsBox;
  late MockBox<MessageModel> mockMessagesBox;
  late MockBox mockSettingsBox;

  setUp(() {
    mockContactsBox = MockBox<Contact>();
    mockMessagesBox = MockBox<MessageModel>();
    mockSettingsBox = MockBox();

    // Instantiate the service and inject the mocks directly.
    // This is the correct way to test the service, avoiding the need for
    // the real Hive.init() and ensuring the service uses our mocks.
    databaseService = DatabaseService(
      contactsBox: mockContactsBox,
      messagesBox: mockMessagesBox,
      settingsBox: mockSettingsBox,
    );
  });

  group('DatabaseService', () {
    test('addContact should add a contact to the contacts box', () async {
      final contact = Contact(
        userId: '1',
        originalPseudo: 'test',
        alias: 'Testy',
        colorValue: 0,
      );
      when(mockContactsBox.put(contact.userId, contact))
          .thenAnswer((_) async => Future.value());
      await databaseService.addContact(contact);
      verify(mockContactsBox.put('1', contact)).called(1);
    });

    test('addMessage should add a message to the messages box', () async {
      final message = MessageModel(
        id: '1',
        senderId: '2',
        receiverId: '3',
        text: 'Hello',
        timestamp: DateTime.now(),
      );
      when(mockMessagesBox.put(message.id, message))
          .thenAnswer((_) async => Future.value());
      await databaseService.addMessage(message);
      verify(mockMessagesBox.put('1', message)).called(1);
    });

    test('getContact should retrieve a contact from the contacts box', () async {
      final contact = Contact(
        userId: '1',
        originalPseudo: 'test',
        alias: 'Testy',
        colorValue: 0,
      );
      when(mockContactsBox.get('1')).thenReturn(contact);
      final result = await databaseService.getContact('1');
      expect(result, contact);
    });

    test('getAllContacts should return a list of all contacts', () async {
      final contacts = [
        Contact(
          userId: '1',
          originalPseudo: 'test1',
          alias: 'Testy1',
          colorValue: 0,
        ),
        Contact(
          userId: '2',
          originalPseudo: 'test2',
          alias: 'Testy2',
          colorValue: 1,
        ),
      ];
      when(mockContactsBox.values).thenReturn(contacts);
      final result = await databaseService.getAllContacts();
      expect(result, contacts);
    });

    test('getMessagesForContact should return all messages for a contact',
        () async {
      final messages = [
        MessageModel(
          id: '1',
          senderId: 'contact1',
          receiverId: 'me',
          text: 'Hello',
          timestamp: DateTime.now(),
        ),
        MessageModel(
          id: '2',
          senderId: 'me',
          receiverId: 'contact1',
          text: 'Hi',
          timestamp: DateTime.now(),
        ),
        MessageModel(
          id: '3',
          senderId: 'contact2',
          receiverId: 'me',
          text: 'Another conversation',
          timestamp: DateTime.now(),
        ),
      ];
      when(mockMessagesBox.values).thenReturn(messages);
      final result = await databaseService.getMessagesForContact('contact1');
      expect(result.length, 2);
      expect(result[0].senderId, 'contact1');
      expect(result[1].receiverId, 'contact1');
    });
  });
}
