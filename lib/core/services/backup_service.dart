import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final DatabaseService _db;

  BackupService(this._db);

  Future<void> exportBackup() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/plop_backup.json';
    final file = File(path);

    final contacts = _db.contactsBox.values.toList();
    final messages = _db.messagesBox.values.toList();
    final contactsOrder = _db.settingsBox.get('contactsOrder', defaultValue: []);

    if (contacts.isEmpty && messages.isEmpty) {
      return;
    }

    final backupData = {
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'contactsOrder': contactsOrder,
    };

    await file.writeAsString(jsonEncode(backupData));

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'Plop Backup');
  }

  Future<bool> importBackup(String jsonString) async {
    try {
      final backupData = jsonDecode(jsonString);

      final contactsData = backupData['contacts'] as List<dynamic>;
      final messagesData = backupData['messages'] as List<dynamic>;
      final contactsOrder = backupData['contactsOrder'] as List<dynamic>;

      final contacts =
          contactsData.map((data) => Contact.fromJson(data)).toList();
      final messages =
          messagesData.map((data) => MessageModel.fromJson(data)).toList();

      await _db.contactsBox.clear();
      await _db.messagesBox.clear();

      for (var contact in contacts) {
        await _db.contactsBox.put(contact.userId, contact);
      }
      for (var message in messages) {
        await _db.messagesBox.put(message.id, message);
      }
      await _db.settingsBox.put('contactsOrder', contactsOrder);

      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }
}
