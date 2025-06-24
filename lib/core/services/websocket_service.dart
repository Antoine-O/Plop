import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
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

  final userService = UserService();
  String? _currentUserId; // NOUVEAU
  String? _currentUserPseudo; // NOUVEAU
  final String _baseUrl = AppConfig.websocketUrl;

  static final WebSocketService _instance =
      WebSocketService._privateConstructor();

  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _pingTimer;

  Stream<Map<String, dynamic>> get messageUpdates =>
      _messageUpdateController.stream;

  int _reconnectAttempts = 0;

  void _handleDisconnect() {
    debugPrint('[WebSocket] WebSocket déconnecté...');
    _pingTimer?.cancel();

    if (_reconnectAttempts < 60) {
      // Limite le nombre de tentatives
      _reconnectAttempts++;
      int reconnectAttempts = _reconnectAttempts - 1;
      if (reconnectAttempts > 8) reconnectAttempts = 8;

      // Attente exponentielle (1s, 2s, 4s, 8s, ...)
      final delay = Duration(seconds: reconnectAttempts);

      Future.delayed(delay, () {
        debugPrint('Reconnexion (tentative $_reconnectAttempts)...');
        // On utilise les informations mémorisées
        if (_currentUserId != null && _currentUserPseudo != null) {
          connect(_currentUserId!, _currentUserPseudo!);
        }
      });
    } else {
      debugPrint('Impossible de se reconnecter après plusieurs tentatives.');
      // Informer l'utilisateur ou arrêter les tentatives
    }
  }

  void connect(String userId, String userPseudo) {
    if (_channel != null) return;
    try {
      _currentUserId = userId;
      _currentUserPseudo = userPseudo;
      debugPrint(
          '[WebSocket] Tentative de connexion pour $userId ($userPseudo)...');
      _channel = WebSocketChannel.connect(
          Uri.parse('$_baseUrl/connect?userId=$userId&pseudo=$userPseudo'));
      _channel!.stream.listen(
        _handleMessage, onDone: _handleDisconnect,
        onError: (error) {
          debugPrint('Erreur WebSocket: $error');
          _handleDisconnect();
        },
        cancelOnError:
            true, // Important pour que onDone soit appelé après une erreur
      );
      // Démarrer le minuteur pour le ping
      _startPing();
    } catch (e) {
      debugPrint('[WebSocket] Erreur de connexion: $e');
    }
  }

  void _startPing() {
    // Annule le minuteur précédent s'il existe
    _pingTimer?.cancel();

    // Envoie un ping toutes les 50 secondes
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (userService.userId == null) userService.init();
      final String? userId = userService.userId;
      final String? username = userService.username;
      final Map<String, dynamic> pingData = {
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
        // Optionnel : pour le débogage
      };
      if (userId != null) {
        pingData.addAll({'userId': userId});
        pingData.addAll({'pseudo': username});
      }
      debugPrint('Sending ping... $userId $username');
      final String jsonPing = jsonEncode(pingData);
      _channel!.sink.add(jsonPing); // Envoyez un message simple comme "ping"
    });
  }

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message);
    final String type = decoded['type'];
    debugPrint('[WebSocket] Message reçu de type: $type');

    switch (type) {
      case 'plop':
        handlePlop(decoded);
        break;
      case 'message_ack':
        _handleMessageAck(decoded['payload']);
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

  // --- AJOUT : NOUVELLE FONCTION POUR TRAITER L'ACK ---
  void _handleMessageAck(Map<String, dynamic> payload) {
    final String? recipientId = payload['recipientId'];
    if (recipientId == null) return;

    debugPrint('[WebSocket] Accusé de réception reçu pour le message envoyé à $recipientId');

    final db = DatabaseService();
    final contact = db.getContact(recipientId);

    if (contact != null) {
      // On met à jour le statut du dernier message envoyé à ce contact
      contact.lastMessageSentStatus = MessageStatus.acknowledged;
      contact.save(); // Sauvegarde la modification dans la base de données

      // On notifie l'interface utilisateur qu'une mise à jour est nécessaire pour ce contact
      _messageUpdateController.add({'userId': recipientId});
    }
  }

  void _handleNewContact(Map<String, dynamic> payload) async {
    final newContact = Contact(
      userId: payload['userId']!,
      originalPseudo: payload['pseudo']!,
      alias: payload['pseudo']!,
      colorValue: Colors
          .primaries[payload['pseudo']!.hashCode % Colors.primaries.length]
          .toARGB32(),
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

    final List<Map<String, dynamic>> contactsJson = contacts
        .map((c) => {
              'userId': c.userId,
              'originalPseudo': c.originalPseudo,
              'alias': c.alias,
              'colorValue': c.colorValue,
              'isMuted': c.isMuted,
              'isBlocked': c.isBlocked,
              'customSoundPath': c.customSoundPath,
              'defaultMessageOverride': c.defaultMessageOverride,
            })
        .toList();

    final List<Map<String, dynamic>> messagesJson = messages
        .map((m) => {
              'id': m.id,
              'text': m.text,
            })
        .toList();

    final syncPayload = {
      'pseudo': userService.username,
      'contacts': contactsJson,
      'messages': messagesJson,
    };

    debugPrint(
        "[WebSocket] Envoi des données de synchronisation : ${jsonEncode(syncPayload)}");
    sendMessage(type: 'sync_data_broadcast', payload: syncPayload);
  }

  // NOUVEAU: Met à jour la base de données locale avec les données reçues
  void _handleSyncDataBroadcast(Map<String, dynamic> payload) async {
    final dbService = DatabaseService();
    final userService = UserService();
    await userService.init();

    debugPrint(
        "[WebSocket] Traitement des données de synchro reçues: $payload");

    if (payload['pseudo'] != null) {
      await userService.updateUsername(payload['pseudo']);
      debugPrint("[WebSocket] Pseudo mis à jour avec : ${payload['pseudo']}");
    }
    bool hasChanged = false;
    if (payload['contacts'] != null) {
      final List<Contact> newContacts = (payload['contacts'] as List)
          .map((cJson) => Contact(
                userId: cJson['userId'],
                originalPseudo: cJson['originalPseudo'],
                alias: cJson['alias'],
                colorValue: cJson['colorValue'],
                isMuted: cJson['isMuted'],
                isBlocked: cJson['isBlocked'],
                customSoundPath: cJson['customSoundPath'],
                defaultMessageOverride: cJson['defaultMessageOverride'],
              ))
          .toList();
      hasChanged = hasChanged || await dbService.mergeContacts(newContacts);
      debugPrint(
          "[WebSocket] ${newContacts.length} contacts ont été remplacés.");
    }

    if (payload['messages'] != null) {
      final List<MessageModel> newMessages = (payload['messages'] as List)
          .map((mJson) => MessageModel(
                id: mJson['id'],
                text: mJson['text'],
              ))
          .toList();
      hasChanged = hasChanged || await dbService.mergeMessages(newMessages);
      debugPrint(
          "[WebSocket] ${newMessages.length} messages rapides ont été remplacés.");
    }

    _messageUpdateController.add({'userId': 'sync_completed'});

    if (hasChanged) {
      _handleSyncRequest();
    }
  }

  void sendMessage(
      {required String type,
      dynamic payload,
      String? to,
      bool isDefault = false}) {
    ensureConnected();
    if (_channel != null) {
      final message = {
        'type': type,
        'to': to,
        'payload': payload,
        'isDefault': isDefault,
      };

      // final db = DatabaseService();
      // final contact = db.getContact(to!);
      // contact?.lastMessageSentStatus = MessageStatus.sending;
      // contact?.lastMessageSentTimestamp = DateTime.now();
      // db.updateContact(contact!);

      try {
        // On essaye d'envoyer le message.
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        // Si une erreur se produit (ex: le canal vient de se fermer), on la propage.
        debugPrint("[WebSocket] Erreur d'envoi du message: $e");
        throw Exception("Erreur d'envoi: $e");
      }

      // contact.lastMessageSentStatus = MessageStatus.sent;
      // contact.lastMessageSentTimestamp = DateTime.now();
      // db.updateContact(contact);
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

  void handlePlop(Map<String, dynamic> data,
      {bool fromExternalNotification = false}) async {
    final fromUserId = data['senderId'] ?? data['from'];
    if (fromUserId == null) {
      debugPrint("[handlePlop] fromUserId is null");
      return;
    }

    final messageText = data['payload'] as String;
    // On récupère le flag pour savoir si c'est un message par défaut
    final bool isDefaultMessage = (data['isDefault'] == 'true');

    final db = DatabaseService();
    final contact = db.getContact(fromUserId);

    if (contact == null || (contact.isBlocked ?? false)) return;

    // CORRECTION : La logique utilise maintenant la variable `isDefaultMessage`
    final bool hasOverride = contact.defaultMessageOverride != null &&
        contact.defaultMessageOverride!.isNotEmpty;
    final String finalMessage = (hasOverride && isDefaultMessage)
        ? contact.defaultMessageOverride!
        : messageText;

    contact.lastMessage = finalMessage;

    contact.lastMessageTimestamp =
        data['sendDate']?.toLocal() ?? DateTime.now();
    await db.updateContact(contact);

    final userService = UserService();
    await userService.init();
    bool isMuted = (contact.isMuted ?? false) == true;
    if (!isMuted && !userService.isGlobalMute && !fromExternalNotification) {
      if (contact.customSoundPath != null &&
          contact.customSoundPath!.isNotEmpty) {
        await _audioPlayer.play(DeviceFileSource(contact.customSoundPath!));
      } else {
        await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
      }

      NotificationService().showNotification(
          title: contact.alias, body: finalMessage, isMuted: isMuted);
    }

    _messageUpdateController.add({'userId': fromUserId});
  }

  Future<void> stopCurrentSound() async {
    await _audioPlayer.stop();
  }

  void ensureConnected() {
    if (_channel == null || _channel!.closeCode != null) {
      debugPrint(
          "[WebSocket] La connexion est coupée. Tentative de rétablissement...");
      _reconnectAttempts =
          0; // Réinitialise les tentatives pour une reconnexion manuelle
      if (_currentUserId != null && _currentUserPseudo != null) {
        _channel = null;
        connect(_currentUserId!, _currentUserPseudo!);
      } else {
        debugPrint(
            "[WebSocket] Impossible de se reconnecter : informations utilisateur manquantes.");
      }
    } else {
      debugPrint("[WebSocket] La connexion est déjà active.");
    }
  }
}
