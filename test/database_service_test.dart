import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUp(() async {
      Hive.init('test');
      Hive.registerAdapter(ContactAdapter());
      Hive.registerAdapter(MessageModelAdapter());
      await Hive.openBox<Contact>('contacts');
      await Hive.openBox<MessageModel>('preconfigured_messages');
      SharedPreferences.setMockInitialValues({});
      databaseService = DatabaseService();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('addContact adds a contact to the database', () async {
      final contact = Contact(
          userId: '1', originalPseudo: 'test', alias: 'test', colorValue: 1);
      await databaseService.addContact(contact);
      final result = databaseService.getContact('1');
      expect(result, equals(contact));
    });

    test('getAllContactsOrdered returns contacts in the correct order',
        () async {
      final contact1 = Contact(
          userId: '1', originalPseudo: 'test1', alias: 'test1', colorValue: 1);
      final contact2 = Contact(
          userId: '2', originalPseudo: 'test2', alias: 'test2', colorValue: 2);
      await databaseService.addContact(contact1);
      await databaseService.addContact(contact2);

      final result = await databaseService.getAllContactsOrdered();
      expect(result, equals([contact1, contact2]));

      await databaseService.saveContactOrder(['2', '1']);

      final newResult = await databaseService.getAllContactsOrdered();
      expect(newResult, equals([contact2, contact1]));
    });
  });
}
