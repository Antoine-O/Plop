import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../models/message_model.dart';


class DatabaseService {
  DatabaseService._privateConstructor();

  static final DatabaseService _instance =
      DatabaseService._privateConstructor();

  factory DatabaseService() {
    return _instance;
  }

  static const String _contactsBoxName = 'contacts';
  static const String _messagesBoxName = 'preconfigured_messages';
  static const String _contactOrderKey = 'contactOrder';

  Future<void> init() async {
    await Hive.openBox<Contact>(_contactsBoxName);
    await Hive.openBox<MessageModel>(_messagesBoxName);
  }

  // --- Opérations sur les Contacts ---

  Box<Contact> get contactsBox => Hive.box<Contact>(_contactsBoxName);

  Future<void> addContact(Contact contact) async {
    await contactsBox.put(contact.userId, contact);
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(_contactOrderKey) ?? [];
    if (!order.contains(contact.userId)) {
      order.add(contact.userId);
      await prefs.setStringList(_contactOrderKey, order);
    }
  }

  Contact? getContact(String userId) => contactsBox.get(userId);

  Future<List<Contact>> getAllContactsOrdered() async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(_contactOrderKey) ?? [];
    final allContacts = contactsBox.values.toList();

    // Assurer la cohérence entre la liste d'ordre et les contacts existants
    final contactMap = {for (var c in allContacts) c.userId: c};
    final consistentOrder =
        order.where((id) => contactMap.containsKey(id)).toList();

    final orderedContacts =
        consistentOrder.map((id) => contactMap[id]!).toList();

    // Ajouter les contacts qui n'étaient pas dans la liste d'ordre (nouveaux ajouts)
    for (var contact in allContacts) {
      if (!consistentOrder.contains(contact.userId)) {
        orderedContacts.add(contact);
      }
    }
    return orderedContacts;
  }

  Future<List<String>> getContactsOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(_contactOrderKey) ?? [];
    return order;
  }

  Future<void> updateContact(Contact contact) async => await contact.save();

  Future<void> deleteContact(String userId) async {
    await contactsBox.delete(userId);
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(_contactOrderKey) ?? [];
    order.remove(userId);
    await prefs.setStringList(_contactOrderKey, order);
  }

  Future<void> saveContactOrder(List<String> orderedUserIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contactOrderKey, orderedUserIds);
  }

  // --- Opérations sur les Messages Préconfigurés ---

  Box<MessageModel> get messagesBox => Hive.box<MessageModel>(_messagesBoxName);

  Future<void> addMessage(MessageModel message) async =>
      await messagesBox.put(message.id, message);

  List<MessageModel> getAllMessages() => messagesBox.values.toList();

  Future<void> deleteMessage(String messageId) async =>
      await messagesBox.delete(messageId);

  Future<void> close() async {
    await contactsBox.close();
    await messagesBox.close();
  }

// NOUVEAU: Remplace tous les contacts et leur ordre
  Future<void> replaceAllContacts(List<Contact> newContacts) async {
    await contactsBox.clear();
    final List<String> orderedIds = [];
    for (var contact in newContacts) {
      await contactsBox.put(contact.userId, contact);
      orderedIds.add(contact.userId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contactOrderKey, orderedIds);
  }

  // NOUVEAU: Remplace tous les contacts et leur ordre
  Future<bool> mergeContacts(List<Contact> newContacts) async {
    bool hasChanged = false;
    // 1. Charger l'ordre existant des IDs depuis SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final List<String> orderedIds = prefs.getStringList(_contactOrderKey) ?? [];

    // 2. Parcourir les nouveaux contacts pour les ajouter ou les mettre à jour.
    for (var contact in newContacts) {
      // La méthode .put() crée ou met à jour l'enregistrement automatiquement.
      // C'est le cœur de l'opération de fusion.
      if (!contactsBox.containsKey(contact.userId)) {
        await contactsBox.put(contact.userId, contact);

        // 3. Mettre à jour la liste d'ordre si le contact est nouveau.
        if (!orderedIds.contains(contact.userId)) {
          // Ajoute les nouveaux contacts à la fin de la liste.
          orderedIds.add(contact.userId);
          hasChanged = true;
        }
      }
    }
    return hasChanged;
  }

  // NOUVEAU: Remplace tous les messages rapides
  Future<void> replaceAllMessages(List<MessageModel> newMessages) async {
    await messagesBox.clear();
    for (var message in newMessages) {
      await messagesBox.put(message.id, message);
    }
  }

  Future<bool> mergeMessages(List<MessageModel> newMessages) async {
    bool hasChanged = false;
    // Parcourt chaque message à fusionner.
    for (var message in newMessages) {
      // La méthode .put() gère à la fois la création et la mise à jour.
      // C'est simple, efficace et fait exactement ce qu'on demande.
      if (!messagesBox.containsKey(message.id)) {
        await messagesBox.put(message.id, message);
        hasChanged = true;
      }
    }
    return hasChanged;
  }

  Future<void> clearContacts() async {
    contactsBox.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_contactOrderKey, []);
  }

  Future<void> setContactOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_contactOrderKey, order);
  }

  Future<void> clearMessages() async {
    messagesBox.clear();
  }
}
