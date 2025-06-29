// lib/core/services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:path_provider/path_provider.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  final String _backupFileName = 'plop_config_backup.json';

  /// Sauvegarde la configuration complète (utilisateur, contacts, messages).
  ///
  /// Si [saveToUserSelectedLocation] est `true`, une boîte de dialogue s'ouvre pour que l'utilisateur choisisse l'emplacement.
  /// Sinon, la sauvegarde est enregistrée dans le répertoire interne de l'application.
  /// Renvoie `null` en cas de succès, ou un message d'erreur `String` en cas d'échec.
  Future<String?> saveBackup({
    required UserService userService,
    required DatabaseService databaseService,
    bool saveToUserSelectedLocation = true,
  }) async {
    debugPrint(
        "[BackupService] saveBackup: Initiating backup process. saveToUserSelectedLocation: $saveToUserSelectedLocation");
    try {
      // 1. Rassembler toutes les données
      final username = userService.username;
      final userId = userService.userId;
      if (username == null || userId == null) {
        debugPrint("[BackupService] saveBackup: User data is not available.");
        return "Les données utilisateur ne sont pas disponibles.";
      }
      debugPrint(
          "[BackupService] saveBackup: User data collected. Username: $username, UserId: $userId");

      final messages = databaseService.getAllMessages();
      final contacts = await databaseService.getAllContactsOrdered();
      final contactsOrder = await databaseService.getContactsOrder();
      debugPrint(
          "[BackupService] saveBackup: Database data collected. Messages count: ${messages.length}, Contacts count: ${contacts.length}, Contacts order count: ${contactsOrder.length}");

      final Map<String, dynamic> configData = {
        'userId': userId,
        'username': username,
        'messages': messages.map((m) => m.toJson()).toList(),
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'contactsOrder': contactsOrder,
      };

      final jsonString = jsonEncode(configData);
      debugPrint(
          "[BackupService] saveBackup: Configuration data encoded to JSON.");

      // 2. Écrire le fichier à l'emplacement choisi
      if (saveToUserSelectedLocation) {
        debugPrint(
            "[BackupService] saveBackup: Requesting user to select save location.");
        final Uint8List fileBytes = utf8.encode(jsonString);
        await FilePicker.platform.saveFile(
          dialogTitle:
              'Veuillez sélectionner un emplacement pour enregistrer votre configuration :',
          fileName: _backupFileName,
          bytes: fileBytes,
        );
        debugPrint(
            "[BackupService] saveBackup: File saved to user selected location.");
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(directory.path, _backupFileName);
        final file = File(filePath);
        await file.writeAsString(jsonString);
        debugPrint(
            "[BackupService] saveBackup: File saved to internal directory: $filePath");
      }
      debugPrint("[BackupService] saveBackup: Backup successful.");
      return null; // Succès
    } catch (e) {
      debugPrint(
          "[BackupService] saveBackup: Error during backup: ${e.toString()}");
      return "Erreur lors de la sauvegarde : ${e.toString()}";
    }
  }

  Future<String?> restoreFromBackup() async {
    debugPrint(
        "[BackupService] restoreFromBackup: Initiating restore process.");
    try {
      // 1. Ouvrir le sélecteur de fichiers pour que l'utilisateur choisisse le backup
      debugPrint("[BackupService] restoreFromBackup: Opening file picker.");
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        debugPrint(
            "[BackupService] restoreFromBackup: File selection cancelled by user.");
        return "Sélection de fichier annulée.";
      }
      final filePath = result.files.single.path!;
      debugPrint("[BackupService] restoreFromBackup: File selected: $filePath");

      // 2. Lire le contenu du fichier
      final file = File(filePath);
      final jsonString = await file.readAsString();
      debugPrint(
          "[BackupService] restoreFromBackup: File content read successfully.");

      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint(
          "[BackupService] restoreFromBackup: JSON data decoded successfully.");

      // 3. Valider le contenu et restaurer les données principales
      if (backupData.containsKey('userId')) {
        debugPrint(
            "[BackupService] restoreFromBackup: 'userId' key found. Proceeding with user data restoration.");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', backupData['userId']!);
        debugPrint(
            "[BackupService] restoreFromBackup: Restored userId: ${backupData['userId']}");

        if (backupData.containsKey('username') &&
            backupData['username'] != null) {
          await prefs.setString('username', backupData['username']!);
          debugPrint(
              "[BackupService] restoreFromBackup: Restored username: ${backupData['username']}");
        } else {
          await prefs.setString('username', 'Utilisateur restauré');
          debugPrint(
              "[BackupService] restoreFromBackup: Restored username with default value: 'Utilisateur restauré'");
        }

        DatabaseService databaseService = DatabaseService();
        debugPrint(
            "[BackupService] restoreFromBackup: DatabaseService instance created.");

        // Restore Contacts
        if (backupData.containsKey('contacts') &&
            backupData['contacts'] is List) {
          debugPrint(
              "[BackupService] restoreFromBackup: 'contacts' key found. Restoring contacts.");
          List contactsListRaw = backupData['contacts'] as List;
          final List<Contact> contactsList = contactsListRaw
              .map((contactJson) =>
                  Contact.fromJson(contactJson as Map<String, dynamic>))
              .toList();
          await databaseService.replaceAllContacts(
              contactsList); // Assuming replaceAllContacts is async
          debugPrint(
              "[BackupService] restoreFromBackup: Replaced all contacts. Count: ${contactsList.length}");

          if (backupData.containsKey('contactsOrder') &&
              backupData['contactsOrder'] is List) {
            debugPrint(
                "[BackupService] restoreFromBackup: 'contactsOrder' key found. Restoring contacts order.");
            List contactsOrderListRaw = backupData['contactsOrder'] as List;
            final List<String> contactsOrderList = // Corrected variable name
                contactsOrderListRaw.cast<String>().toList();
            await databaseService.setContactOrder(
                contactsOrderList); // Assuming setContactOrder is async
            debugPrint(
                "[BackupService] restoreFromBackup: Set contact order. Count: ${contactsOrderList.length}");
          } else {
            debugPrint(
                "[BackupService] restoreFromBackup: 'contactsOrder' key not found or invalid. Skipping contacts order restoration.");
          }
        } else {
          debugPrint(
              "[BackupService] restoreFromBackup: 'contacts' key not found or invalid. Clearing contacts.");
          await databaseService
              .clearContacts(); // Assuming clearContacts is async
        }

        // Restore Messages
        if (backupData.containsKey('messages') &&
            backupData['messages'] is List) {
          debugPrint(
              "[BackupService] restoreFromBackup: 'messages' key found. Restoring messages.");
          List messagesListRaw = backupData['messages'] as List;
          final List<MessageModel> messagesList = messagesListRaw
              .map((messageJson) =>
                  MessageModel.fromJson(messageJson as Map<String, dynamic>))
              .toList();
          await databaseService.replaceAllMessages(
              messagesList); // Assuming replaceAllMessages is async
          debugPrint(
              "[BackupService] restoreFromBackup: Replaced all messages. Count: ${messagesList.length}");
        } else {
          debugPrint(
              "[BackupService] restoreFromBackup: 'messages' key not found or invalid. Clearing messages.");
          await databaseService
              .clearMessages(); // Assuming clearMessages is async
        }

        debugPrint(
            "[BackupService] restoreFromBackup: Restore process completed successfully.");
        return null; // Succès !
      } else {
        debugPrint(
            "[BackupService] restoreFromBackup: Invalid backup file. 'userId' key missing.");
        return 'Fichier de sauvegarde invalide ou corrompu.';
      }
    } catch (e, stackTrace) {
      debugPrint(
          "[BackupService] restoreFromBackup: Error during restore: ${e.toString()}");
      debugPrintStack(
          stackTrace: stackTrace,
          label: "[BackupService] restoreFromBackup StackTrace");
      return "Une erreur est survenue lors de la restauration : ${e.toString()}";
    }
  }
}
