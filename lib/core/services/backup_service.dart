// lib/core/services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
    try {
      // 1. Rassembler toutes les données
      final username = userService.username;
      final userId = userService.userId;
      if (username == null || userId == null) {
        return "Les données utilisateur ne sont pas disponibles.";
      }
      final messages = databaseService.getAllMessages();
      final contacts = await databaseService.getAllContactsOrdered();
      final contactsOrder = await databaseService.getContactsOrder();

      final Map<String, dynamic> configData = {
        'userId': userId,
        'username': username,
        'messages': messages.map((m) => m.toJson()).toList(),
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'contactsOrder': contactsOrder,
      };

      final jsonString = jsonEncode(configData);

      // 2. Écrire le fichier à l'emplacement choisi
      if (saveToUserSelectedLocation) {
        final Uint8List fileBytes = utf8.encode(jsonString);
        await FilePicker.platform.saveFile(
          dialogTitle:
              'Veuillez sélectionner un emplacement pour enregistrer votre configuration :',
          fileName: _backupFileName,
          bytes: fileBytes,
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(directory.path, _backupFileName);
        final file = File(filePath);
        await file.writeAsString(jsonString);
      }
      return null; // Succès
    } catch (e) {
      return "Erreur lors de la sauvegarde : ${e.toString()}";
    }
  }

  Future<String?> restoreFromBackup() async {
    try {
      // 1. Ouvrir le sélecteur de fichiers pour que l'utilisateur choisisse le backup
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        // L'utilisateur a annulé la sélection, ce n'est pas une erreur mais une action nulle.
        // On pourrait retourner un message spécifique si on voulait le traiter différemment.
        return "Sélection de fichier annulée.";
      }

      // 2. Lire le contenu du fichier
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 3. Valider le contenu et restaurer les données principales
      if (backupData.containsKey('userId')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', backupData['userId']!);

        if (backupData.containsKey('username') &&
            backupData['username'] != null) {
          await prefs.setString('username', backupData['username']!);
        } else {
          await prefs.setString('username', 'Utilisateur restauré');
        }

        DatabaseService databaseService = DatabaseService();
        if (backupData.containsKey('contacts') &&
            backupData['contacts'] is List) {
          List contactsListRaw = backupData['contacts'] as List;
          final List<Contact> contactsList = contactsListRaw
              .map((contactJson) =>
                  Contact.fromJson(contactJson as Map<String, dynamic>))
              .toList();
          databaseService.replaceAllContacts(contactsList);
          if (backupData.containsKey('contactsOrder') &&
              backupData['contactsOrder'] is List) {
            List contactsOrderListRaw = backupData['contactsOrder'] as List;
            final List<String> contactsList =
                contactsOrderListRaw.cast<String>().toList();
            databaseService.setContactOrder(contactsList);
          }
        } else {
          databaseService.clearContacts();
        }

        if (backupData.containsKey('messages') &&
            backupData['messages'] is List) {
          List messagesListRaw = backupData['messages'] as List;
          final List<MessageModel> messagesList = messagesListRaw
              .map((messageJson) =>
                  MessageModel.fromJson(messageJson as Map<String, dynamic>))
              .toList();
          databaseService.replaceAllMessages(messagesList);
        } else {
          databaseService.clearMessages();
        }

        // Succès ! On renvoie null.
        return null;
      } else {
        // Le fichier ne contient pas les données attendues.
        return 'Fichier de sauvegarde invalide ou corrompu.';
      }
    } catch (e) {
      // Une erreur inattendue est survenue (lecture de fichier, parsing JSON, etc.)
      return "Une erreur est survenue lors de la restauration : ${e.toString()}";
    }
  }
}
