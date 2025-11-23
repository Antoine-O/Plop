import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hive_ce/hive.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';


class DatabaseService {
  late Box<Contact> _contactsBox;
  late Box<MessageModel> _messagesBox;
  late Box _settingsBox;

  Box<Contact> get contactsBox => _contactsBox;
  Box<MessageModel> get messagesBox => _messagesBox;
  Box get settingsBox => _settingsBox;

  DatabaseService(
      {Box<Contact>? contactsBox,
      Box<MessageModel>? messagesBox,
      Box? settingsBox}) {
    if (contactsBox != null) _contactsBox = contactsBox;
    if (messagesBox != null) _messagesBox = messagesBox;
    if (settingsBox != null) _settingsBox = settingsBox;
  }

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(MessageModelAdapter());

    _contactsBox = await Hive.openBox<Contact>('contacts');
    _messagesBox = await Hive.openBox<MessageModel>('messages');
    _settingsBox = await Hive.openBox('settings');
  }

  Future<void> addContact(Contact contact) async {
    await _contactsBox.put(contact.userId, contact);
  }

  Future<void> addMessage(MessageModel message) async {
    await _messagesBox.put(message.id, message);
  }

  Future<Contact?> getContact(String contactId) async {
    return _contactsBox.get(contactId);
  }

  Future<MessageModel?> getMessage(String messageId) async {
    return _messagesBox.get(messageId);
  }

  Future<List<Contact>> getAllContacts() async {
    return _contactsBox.values.toList();
  }

  Future<List<Contact>> getAllContactsOrdered() async {
    final contacts = await getAllContacts();
    contacts.sort((a, b) => a.alias.compareTo(b.alias));
    return contacts;
  }

  Future<List<MessageModel>> getMessagesForContact(String contactId) async {
    return _messagesBox.values
        .where((message) =>
            message.senderId == contactId || message.receiverId == contactId)
        .toList();
  }

  Future<void> clearAllData() async {
    await _contactsBox.clear();
    await _messagesBox.clear();
  }
}
