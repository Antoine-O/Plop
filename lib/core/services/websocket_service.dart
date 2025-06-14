import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:plop/core/config/app_config.dart';

class WebSocketService {
  WebSocketService._privateConstructor();
  static final WebSocketService _instance = WebSocketService._privateConstructor();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  final String _baseUrl =  AppConfig.websocketUrl;
  final _messageUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Stream<Map<String, dynamic>> get messageUpdates => _messageUpdateController.stream;

  void connect(String userId, String userPseudo) {
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_baseUrl/connect?userId=$userId&pseudo=$userPseudo'));
      _channel!.stream.listen(_handleMessage, onError: (error) {
        debugPrint('[WebSocket] Erreur: $error');
        _channel = null;
      }, onDone: () {
        debugPrint('[WebSocket] Déconnecté.');
        _channel = null;
      });
    } catch (e) {
      debugPrint('[WebSocket] Erreur de connexion: $e');
    }
  }

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message);
    final String type = decoded['type'];
    debugPrint('[WebSocket] Message reçu de type: $type');

    switch (type) {
      case 'plop':
        _handlePlop(decoded);
        break;
      case 'new_contact':
        _handleNewContact(decoded['payload']);
        break;
      case 'sync_request':
        debugPrint('[WebSocket] Demande de synchronisation reçue.');
        _handleSyncRequest();
        break;
      case 'sync_data_broadcast':
        debugPrint('[WebSocket] Données de synchronisation reçues.');
        _handleSyncDataBroadcast(decoded['payload']);
        break;
      default:
        debugPrint('[WebSocket] Message inconnu: $message');
    }
  }

  void _handleNewContact(Map<String, dynamic> payload) async {
    final newContact = Contact(
      userId: payload['userId']!,
      originalPseudo: payload['pseudo']!,
      alias: payload['pseudo']!,
      colorValue: Colors.primaries[payload['pseudo']!.hashCode % Colors.primaries.length].value,
    );
    await DatabaseService().addContact(newContact);
    _messageUpdateController.add({'userId': 'new_contact_added'});
  }

// NOUVEAU: Envoie les données locales à tous les autres appareils
  void _handleSyncRequest() async {
    final dbService = DatabaseService();
    final userService = UserService();
    await userService.init();

    final contacts = await dbService.getAllContactsOrdered();
    final messages = dbService.getAllMessages();

    final List<Map<String, dynamic>> contactsJson = contacts.map((c) => {
      'userId': c.userId,
      'originalPseudo': c.originalPseudo,
      'alias': c.alias,
      'colorValue': c.colorValue,
      'isMuted': c.isMuted,
      'isBlocked': c.isBlocked,
      'customSoundPath': c.customSoundPath,
      'defaultMessageOverride': c.defaultMessageOverride,
    }).toList();

    final List<Map<String, dynamic>> messagesJson = messages.map((m) => {
      'id': m.id,
      'text': m.text,
    }).toList();

    final syncPayload = {
      'pseudo': userService.username,
      'contacts': contactsJson,
      'messages': messagesJson,
    };

    debugPrint("[WebSocket] Envoi des données de synchronisation : ${jsonEncode(syncPayload)}");
    sendMessage(type: 'sync_data_broadcast', payload: syncPayload);
  }

  // NOUVEAU: Met à jour la base de données locale avec les données reçues
  void _handleSyncDataBroadcast(Map<String, dynamic> payload) async {
    final dbService = DatabaseService();
    final userService = UserService();
    await userService.init();

    debugPrint("[WebSocket] Traitement des données de synchro reçues: $payload");

    if (payload['pseudo'] != null) {
      await userService.updateUsername(payload['pseudo']);
      debugPrint("[WebSocket] Pseudo mis à jour avec : ${payload['pseudo']}");
    }

    if (payload['contacts'] != null) {
      final List<Contact> newContacts = (payload['contacts'] as List).map((cJson) => Contact(
        userId: cJson['userId'],
        originalPseudo: cJson['originalPseudo'],
        alias: cJson['alias'],
        colorValue: cJson['colorValue'],
        isMuted: cJson['isMuted'],
        isBlocked: cJson['isBlocked'],
        customSoundPath: cJson['customSoundPath'],
        defaultMessageOverride: cJson['defaultMessageOverride'],
      )).toList();
      await dbService.replaceAllContacts(newContacts);
      debugPrint("[WebSocket] ${newContacts.length} contacts ont été remplacés.");
    }

    if (payload['messages'] != null) {
      final List<MessageModel> newMessages = (payload['messages'] as List).map((mJson) => MessageModel(
        id: mJson['id'],
        text: mJson['text'],
      )).toList();
      await dbService.replaceAllMessages(newMessages);
      debugPrint("[WebSocket] ${newMessages.length} messages rapides ont été remplacés.");
    }

    _messageUpdateController.add({'userId': 'sync_completed'});
  }

  void sendMessage({required String type, dynamic payload, String? to, bool isDefault = false}) {
    if (_channel != null) {
      final message = {
        'type': type,
        'to': to,
        'payload': payload,
        'isDefault': isDefault,
      };
      _channel!.sink.add(jsonEncode(message));
    }
  }


  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _messageUpdateController.close();
    _audioPlayer.dispose();
  }
  void _handlePlop(Map<String, dynamic> data) async {
    final fromUserId = data['from'] as String;
    final messageText = data['payload'] as String;
    // On récupère le flag pour savoir si c'est un message par défaut
    final bool isDefaultMessage = data['isDefault'] as bool? ?? false;

    final db = DatabaseService();
    final contact = db.getContact(fromUserId);

    if (contact == null || (contact.isBlocked ?? false)) return;

    // CORRECTION : La logique utilise maintenant la variable `isDefaultMessage`
    final bool hasOverride = contact.defaultMessageOverride != null && contact.defaultMessageOverride!.isNotEmpty;
    final String finalMessage = (hasOverride && isDefaultMessage)
        ? contact.defaultMessageOverride!
        : messageText;

    contact.lastMessage = finalMessage;
    contact.lastMessageTimestamp = DateTime.now();
    await db.updateContact(contact);

    final userService = UserService();
    await userService.init();

    if ((contact.isMuted ?? false) == false && !userService.isGlobalMute) {
      if (contact.customSoundPath != null && contact.customSoundPath!.isNotEmpty) {
        await _audioPlayer.play(DeviceFileSource(contact.customSoundPath!));
      } else {
        await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
      }

      NotificationService().showNotification(
        title: 'Nouveau Plop de ${contact.alias}',
        body: finalMessage,
      );
    }

    _messageUpdateController.add({'userId': fromUserId});
  }
  Future<void> stopCurrentSound() async {
    await _audioPlayer.stop();
  }
}
