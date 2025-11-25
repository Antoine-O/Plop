import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_test/hive_ce_test.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUp(() async {
      await setUpTestHive();
      databaseService = DatabaseService();
      await databaseService.init();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    final contact1 =
        Contact(userId: '1', originalPseudo: 'a', alias: 'a', colorValue: 1);
    final contact2 =
        Contact(userId: '2', originalPseudo: 'b', alias: 'b', colorValue: 2);
    final message1 = MessageModel(id: '1', text: 'a');
    final message2 = MessageModel(id: '2', text: 'b');

    test('addContact adds a contact and updates order', () async {
      await databaseService.addContact(contact1);
      expect(databaseService.getContact('1'), contact1);
      final order = await databaseService.getContactsOrder();
      expect(order, ['1']);
    });

    test('getContact retrieves a contact', () async {
      await databaseService.addContact(contact1);
      expect(databaseService.getContact('1'), contact1);
    });

    test('getAllContactsOrdered retrieves contacts in the correct order',
        () async {
      await databaseService.addContact(contact1);
      await databaseService.addContact(contact2);
      await databaseService.saveContactOrder(['2', '1']);
      final contacts = await databaseService.getAllContactsOrdered();
      expect(contacts, [contact2, contact1]);
    });

    test('updateContact updates a contact', () async {
      await databaseService.addContact(contact1);
      contact1.alias = 'c';
      await databaseService.updateContact(contact1);
      expect(databaseService.getContact('1')?.alias, 'c');
    });

    test('deleteContact deletes a contact and updates order', () async {
      await databaseService.addContact(contact1);
      await databaseService.addContact(contact2);
      await databaseService.deleteContact('1');
      expect(databaseService.getContact('1'), isNull);
      final order = await databaseService.getContactsOrder();
      expect(order, ['2']);
    });

    test('saveContactOrder saves the contact order', () async {
      await databaseService.saveContactOrder(['2', '1']);
      final order = await databaseService.getContactsOrder();
      expect(order, ['2', '1']);
    });

    test('addMessage adds a message', () async {
      await databaseService.addMessage(message1);
      expect(databaseService.getAllMessages(), [message1]);
    });

    test('getAllMessages retrieves all messages', () async {
      await databaseService.addMessage(message1);
      await databaseService.addMessage(message2);
      expect(databaseService.getAllMessages(), [message1, message2]);
    });

    test('deleteMessage deletes a message', () async {
      await databaseService.addMessage(message1);
      await databaseService.addMessage(message2);
      await databaseService.deleteMessage('1');
      expect(databaseService.getAllMessages(), [message2]);
    });

    test('replaceAllContacts replaces all contacts and their order', () async {
      await databaseService.addContact(contact1);
      await databaseService.replaceAllContacts([contact2]);
      expect(databaseService.getContact('1'), isNull);
      expect(databaseService.getContact('2'), contact2);
      final order = await databaseService.getContactsOrder();
      expect(order, ['2']);
    });

    test('mergeContacts merges new contacts', () async {
      await databaseService.addContact(contact1);
      final hasChanged = await databaseService.mergeContacts([contact2]);
      expect(hasChanged, isTrue);
      expect(databaseService.getContact('1'), contact1);
      expect(databaseService.getContact('2'), contact2);
      final order = await databaseService.getContactsOrder();
      expect(order, ['1', '2']);
    });

    test('replaceAllMessages replaces all messages', () async {
      await databaseService.addMessage(message1);
      await databaseService.replaceAllMessages([message2]);
      expect(databaseService.getAllMessages(), [message2]);
    });

    test('mergeMessages merges new messages', () async {
      await databaseService.addMessage(message1);
      final hasChanged = await databaseService.mergeMessages([message2]);
      expect(hasChanged, isTrue);
      expect(databaseService.getAllMessages(), [message1, message2]);
    });

    test('clearContacts clears all contacts and their order', () async {
      await databaseService.addContact(contact1);
      await databaseService.clearContacts();
      expect(databaseService.contactsBox.isEmpty, isTrue);
      final order = await databaseService.getContactsOrder();
      expect(order, isEmpty);
    });

    test('setContactOrder sets the contact order', () async {
      await databaseService.setContactOrder(['2', '1']);
      final order = await databaseService.getContactsOrder();
      expect(order, ['2', '1']);
    });

    test('clearMessages clears all messages', () async {
      await databaseService.addMessage(message1);
      await databaseService.clearMessages();
      expect(databaseService.messagesBox.isEmpty, isTrue);
    });
  });
}
