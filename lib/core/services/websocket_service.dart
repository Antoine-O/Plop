import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
// Import for debugPrint
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:plop/core/config/app_config.dart';

class WebSocketService {
  WebSocketService._privateConstructor() {
    debugPrint("[WebSocketService] _privateConstructor: Instance created.");
  }

  final userService = UserService();
  final notificationService = NotificationService();
  String? _currentUserId;
  String? _currentUserPseudo;
  final String _baseUrl = AppConfig.websocketUrl;

  static final WebSocketService _instance =
      WebSocketService._privateConstructor();

  factory WebSocketService() {
    // debugPrint("[WebSocketService] factory: Returning singleton instance."); // Can be verbose
    return _instance;
  }

  WebSocketChannel? _channel;
  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _pingTimer;

  Stream<Map<String, dynamic>> get messageUpdates {
    // debugPrint("[WebSocketService] messageUpdates: Stream accessed."); // Can be verbose
    return _messageUpdateController.stream;
  }

  int _reconnectAttempts = 0;

  void _handleDisconnect() {
    debugPrint(
        '[WebSocketService] _handleDisconnect: WebSocket disconnected. Current reconnect attempts: $_reconnectAttempts');
    _pingTimer?.cancel();
    debugPrint('[WebSocketService] _handleDisconnect: Ping timer cancelled.');

    if (_reconnectAttempts < 60) {
      _reconnectAttempts++;
      int reconnectDelayFactor = _reconnectAttempts - 1;
      if (reconnectDelayFactor > 8) {
        reconnectDelayFactor = 8; // Cap delay factor
      }

      final delay = Duration(seconds: reconnectDelayFactor);
      debugPrint(
          '[WebSocketService] _handleDisconnect: Will attempt reconnection (attempt #$_reconnectAttempts) in $delay seconds.');

      Future.delayed(delay, () {
        debugPrint(
            '[WebSocketService] _handleDisconnect: Attempting reconnection #$_reconnectAttempts...');
        if (_currentUserId != null && _currentUserPseudo != null) {
          debugPrint(
              '[WebSocketService] _handleDisconnect: Stored user ID ($_currentUserId) and pseudo ($_currentUserPseudo) found. Calling connect.');
          connect(_currentUserId!, _currentUserPseudo!);
        } else {
          debugPrint(
              '[WebSocketService] _handleDisconnect: Cannot reconnect, currentUserId or currentUserPseudo is null.');
        }
      });
    } else {
      debugPrint(
          '[WebSocketService] _handleDisconnect: Maximum reconnection attempts reached. Stopping reconnection attempts.');
      // Informer l'utilisateur ou arrêter les tentatives
    }
  }

  void connect(String userId, String userPseudo) {
    debugPrint(
        '[WebSocketService] connect: Attempting to connect for userId: $userId, pseudo: $userPseudo');
    if (_channel != null && _channel?.closeCode == null) {
      // Check if already connected and open
      debugPrint(
          '[WebSocketService] connect: Channel already exists and seems open. Aborting new connection.');
      return;
    }
    try {
      _currentUserId = userId;
      _currentUserPseudo = userPseudo;
      debugPrint(
          '[WebSocketService] connect: Stored _currentUserId: $_currentUserId, _currentUserPseudo: $_currentUserPseudo');
      final uri =
          Uri.parse('$_baseUrl/connect?userId=$userId&pseudo=$userPseudo');
      debugPrint('[WebSocketService] connect: Connecting to URI: $uri');
      _channel = WebSocketChannel.connect(uri);
      debugPrint(
          '[WebSocketService] connect: WebSocketChannel created. Listening to stream.');
      _channel!.stream.listen(
        (message) {
          // _handleMessage renamed to message for clarity in this scope
          // debugPrint('[WebSocketService] connect: Raw message received on stream: $message'); // Can be very verbose
          _handleMessage(message);
        },
        onDone: () {
          debugPrint(
              '[WebSocketService] connect: WebSocket stream onDone triggered.');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint(
              '[WebSocketService] connect: WebSocket stream onError: $error');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
      _reconnectAttempts =
          0; // Reset on successful connection attempt initiation
      debugPrint('[WebSocketService] connect: Reconnect attempts reset to 0.');
      _startPing();
      debugPrint('[WebSocketService] connect: Connection process initiated.');
    } catch (e, stackTrace) {
      debugPrint(
          '[WebSocketService] connect: ERROR during connection attempt: $e');
      debugPrintStack(
          stackTrace: stackTrace, label: '[WebSocketService] connect Error');
    }
  }

  void _startPing() {
    debugPrint(
        '[WebSocketService] _startPing: Attempting to start ping timer.');
    _pingTimer?.cancel();
    debugPrint(
        '[WebSocketService] _startPing: Previous ping timer (if any) cancelled.');

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // Marked async for userService.init()
      // debugPrint('[WebSocketService] _startPing: Ping timer ticked.'); // Can be verbose
      if (userService.userId == null) {
        debugPrint(
            '[WebSocketService] _startPing: userService.userId is null. Initializing userService.');
        await userService.init(); // Assuming init might be async
      }
      final String? userId = userService.userId;
      final String? username = userService.username;
      final Map<String, dynamic> pingData = {
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (userId != null) {
        pingData['userId'] = userId;
        pingData['pseudo'] =
            username; // Assuming username corresponds to pseudo for ping
      }
      final String jsonPing = jsonEncode(pingData);
      debugPrint('[WebSocketService] _startPing: Sending ping: $jsonPing');
      try {
        if (_channel != null && _channel?.closeCode == null) {
          _channel!.sink.add(jsonPing);
          // debugPrint('[WebSocketService] _startPing: Ping message added to sink.'); // Can be verbose
        } else {
          debugPrint(
              '[WebSocketService] _startPing: Cannot send ping, channel is null or closed.');
        }
      } catch (e, stackTrace) {
        debugPrint('[WebSocketService] _startPing: ERROR sending ping: $e');
        debugPrintStack(
            stackTrace: stackTrace,
            label: '[WebSocketService] _startPing Error');
        // Optionally, handle specific errors like broken pipe by attempting to reconnect
      }
    });
    debugPrint(
        '[WebSocketService] _startPing: Ping timer started. Interval: 30 seconds.');
  }

  void _handleMessage(dynamic message) {
    debugPrint(
        '[WebSocketService] _handleMessage: Handling raw message: $message');
    try {
      final decoded = jsonDecode(message);
      final String type = decoded['type'];
      debugPrint(
          '[WebSocketService] _handleMessage: Decoded message type: $type. Full decoded: $decoded');

      switch (type) {
        case 'plop':
          debugPrint('[WebSocketService] _handleMessage: Matched type "plop".');
          handlePlop(decoded);
          break;
        case 'message_ack':
          debugPrint(
              '[WebSocketService] _handleMessage: Matched type "message_ack".');
          _handleMessageAck(decoded['payload']);
          break;
        case 'new_contact':
          debugPrint(
              '[WebSocketService] _handleMessage: Matched type "new_contact".');
          _handleNewContact(decoded['payload']);
          break;
        case 'sync_request':
          debugPrint(
              '[WebSocketService] _handleMessage: Matched type "sync_request".');
          _handleSyncRequest();
          break;
        case 'sync_data_broadcast':
          debugPrint(
              '[WebSocketService] _handleMessage: Matched type "sync_data_broadcast".');
          _handleSyncDataBroadcast(decoded['payload']);
          break;
        default:
          debugPrint(
              '[WebSocketService] _handleMessage: Unknown message type: $type. Message: $message');
      }
    } catch (e, stackTrace) {
      debugPrint(
          '[WebSocketService] _handleMessage: ERROR processing message: $e. Original message: $message');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] _handleMessage Error');
    }
  }

  void _handleMessageAck(Map<String, dynamic> payload) {
    debugPrint(
        '[WebSocketService] _handleMessageAck: Processing message acknowledgement. Payload: $payload');
    final String? recipientId = payload['recipientId'];
    if (recipientId == null) {
      debugPrint(
          '[WebSocketService] _handleMessageAck: recipientId is null in payload. Aborting.');
      return;
    }

    debugPrint(
        '[WebSocketService] _handleMessageAck: Ack received for message sent to $recipientId');

    final db = DatabaseService();
    final contact = db.getContact(recipientId); // This is synchronous

    if (contact != null) {
      debugPrint(
          '[WebSocketService] _handleMessageAck: Contact $recipientId found. Updating lastMessageSentStatus.');
      contact.lastMessageSentStatus = MessageStatus.acknowledged;
      contact.save(); // Assuming HiveObject.save() is synchronous
      debugPrint(
          '[WebSocketService] _handleMessageAck: Contact $recipientId saved with acknowledged status.');

      _messageUpdateController.add(
          {'userId': recipientId, 'type': 'ack'}); // Added type for clarity
      debugPrint(
          '[WebSocketService] _handleMessageAck: Update added to _messageUpdateController for userId: $recipientId');
    } else {
      debugPrint(
          '[WebSocketService] _handleMessageAck: Contact $recipientId not found. Cannot process ack.');
    }
  }

  void _handleNewContact(Map<String, dynamic> payload) async {
    debugPrint(
        '[WebSocketService] _handleNewContact: Processing new contact. Payload: $payload');
    try {
      final newContact = Contact(
        userId: payload['userId']!,
        originalPseudo: payload['pseudo']!,
        alias: payload['pseudo']!,
        colorValue: Colors
            .primaries[payload['pseudo']!.hashCode % Colors.primaries.length]
            .value, // Use .value for ARGB32
      );
      debugPrint(
          '[WebSocketService] _handleNewContact: Created new Contact object for userId: ${newContact.userId}');
      await DatabaseService().addContact(newContact);
      debugPrint(
          '[WebSocketService] _handleNewContact: New contact ${newContact.userId} added to database.');
      _messageUpdateController.add(
          {'userId': 'new_contact_added', 'newContactId': newContact.userId});
      debugPrint(
          '[WebSocketService] _handleNewContact: Update "new_contact_added" sent to _messageUpdateController.');
    } catch (e, stackTrace) {
      debugPrint(
          '[WebSocketService] _handleNewContact: ERROR processing new contact: $e. Payload: $payload');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] _handleNewContact Error');
    }
  }

  void _handleSyncRequest() async {
    debugPrint(
        "[WebSocketService] _handleSyncRequest: Received sync request. Preparing to send local data.");
    try {
      final dbService = DatabaseService();
      final localUserService =
          UserService(); // Local instance to avoid conflicts with class member
      await localUserService.init();
      debugPrint(
          "[WebSocketService] _handleSyncRequest: UserService initialized. Current user: ${localUserService.username}");

      final contacts = await dbService.getAllContactsOrdered();
      final messages = dbService.getAllMessages(); // This is synchronous
      debugPrint(
          "[WebSocketService] _handleSyncRequest: Fetched ${contacts.length} contacts and ${messages.length} messages from local DB.");

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
                'id': m.id, // Assuming MessageModel has an id
                'text': m.text,
                // Add other relevant MessageModel fields here
              })
          .toList();

      final syncPayload = {
        'pseudo': localUserService.username,
        'contacts': contactsJson,
        'messages': messagesJson,
      };

      final jsonPayloadString = jsonEncode(syncPayload);
      // debugPrint("[WebSocketService] _handleSyncRequest: Sending sync_data_broadcast with payload: $jsonPayloadString"); // Can be very verbose
      debugPrint(
          "[WebSocketService] _handleSyncRequest: Sending sync_data_broadcast. Contacts: ${contactsJson.length}, Messages: ${messagesJson.length}");
      sendMessage(type: 'sync_data_broadcast', payload: syncPayload);
    } catch (e, stackTrace) {
      debugPrint(
          "[WebSocketService] _handleSyncRequest: ERROR preparing or sending sync data: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] _handleSyncRequest Error');
    }
  }

  void _handleSyncDataBroadcast(Map<String, dynamic> payload) async {
    debugPrint(
        "[WebSocketService] _handleSyncDataBroadcast: Received sync data broadcast. Payload keys: ${payload.keys}");
    try {
      final dbService = DatabaseService();
      final localUserService = UserService();
      await localUserService
          .init(); // Ensure initialized before potential update

      final receivedPseudo = payload['pseudo'] as String?;
      debugPrint(
          "[WebSocketService] _handleSyncDataBroadcast: Received pseudo: $receivedPseudo. Current local pseudo: ${localUserService.username}");

      if (receivedPseudo != null &&
          receivedPseudo != localUserService.username) {
        // Only update if different to avoid unnecessary writes and notifications
        await localUserService.updateUsername(receivedPseudo);
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: Local username updated to: $receivedPseudo");
      }

      bool hasChanged = false;

      if (payload['contacts'] != null && payload['contacts'] is List) {
        final List<dynamic> contactsData = payload['contacts'] as List<dynamic>;
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: Processing ${contactsData.length} received contacts.");
        final List<Contact> newContacts = contactsData
            .map((cJson) => Contact(
                  // Assuming Contact.fromJson exists or direct mapping
                  userId: cJson['userId'] as String,
                  originalPseudo: cJson['originalPseudo'] as String,
                  alias: cJson['alias'] as String,
                  colorValue: cJson['colorValue'] as int,
                  isMuted: cJson['isMuted'] as bool? ?? false,
                  isBlocked: cJson['isBlocked'] as bool? ?? false,
                  customSoundPath: cJson['customSoundPath'] as String?,
                  defaultMessageOverride:
                      cJson['defaultMessageOverride'] as String?,
                ))
            .toList();
        // Assuming mergeContacts returns a bool indicating if changes were made
        bool contactsChanged = await dbService.mergeContacts(newContacts);
        if (contactsChanged) hasChanged = true;
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: ${newContacts.length} contacts merged. Changes made: $contactsChanged");
      } else {
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: No 'contacts' field or invalid format in sync data.");
      }

      if (payload['messages'] != null && payload['messages'] is List) {
        final List<dynamic> messagesData = payload['messages'] as List<dynamic>;
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: Processing ${messagesData.length} received messages.");
        final List<MessageModel> newMessages = messagesData
            .map((mJson) => MessageModel(
                  // Assuming MessageModel.fromJson or direct mapping
                  id: mJson['id'] as String,
                  text: mJson['text'] as String,
                  // Map other necessary fields from mJson
                ))
            .toList();
        // Assuming mergeMessages returns a bool indicating if changes were made
        bool messagesChanged = await dbService.mergeMessages(newMessages);
        if (messagesChanged) hasChanged = true;
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: ${newMessages.length} messages merged. Changes made: $messagesChanged");
      } else {
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: No 'messages' field or invalid format in sync data.");
      }

      _messageUpdateController
          .add({'userId': 'sync_completed', 'changesMade': hasChanged});
      debugPrint(
          "[WebSocketService] _handleSyncDataBroadcast: Update 'sync_completed' sent to _messageUpdateController. Changes made: $hasChanged");

      if (hasChanged) {
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: Local data changed after sync. Triggering another sync request to propagate these merged changes.");
        _handleSyncRequest(); // Propagate merged changes if local data was modified
      } else {
        debugPrint(
            "[WebSocketService] _handleSyncDataBroadcast: No local data changed after sync. No further sync request triggered.");
      }
    } catch (e, stackTrace) {
      debugPrint(
          "[WebSocketService] _handleSyncDataBroadcast: ERROR processing sync data: $e. Payload: $payload");
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] _handleSyncDataBroadcast Error');
    }
  }

  void sendMessage(
      {required String type,
      dynamic payload,
      String? to,
      bool isDefault = false}) {
    debugPrint(
        '[WebSocketService] sendMessage: Attempting to send message. Type: $type, To: $to, IsDefault: $isDefault, Payload: $payload');
    ensureConnected(); // This has its own logs
    if (_channel != null && _channel?.closeCode == null) {
      final message = {
        'type': type,
        'to': to,
        'payload': payload,
        'isDefault': isDefault,
        'senderId': _currentUserId, // Automatically add senderId
        'senderPseudo': _currentUserPseudo, // Automatically add senderPseudo
        'sendDate': DateTime.now().toIso8601String(), // Add send date
      };
      final jsonMessage = jsonEncode(message);
      // debugPrint('[WebSocketService] sendMessage: Full JSON message to send: $jsonMessage'); // Can be verbose

      try {
        _channel!.sink.add(jsonMessage);
        debugPrint(
            '[WebSocketService] sendMessage: Message added to sink. Type: $type, To: $to');
        // Update local contact state for sending (optimistic update)
        if (to != null) {
          final db = DatabaseService();
          final contact = db.getContact(to);
          if (contact != null) {
            contact.lastMessageSentStatus = MessageStatus.sending;
            contact.lastMessageSentTimestamp = DateTime.now();
            contact.save();
            debugPrint(
                '[WebSocketService] sendMessage: Contact $to status updated to sending.');
            _messageUpdateController
                .add({'userId': to, 'type': 'status_update'});
          }
        }
      } catch (e, stackTrace) {
        debugPrint("[WebSocketService] sendMessage: ERROR sending message: $e");
        debugPrintStack(
            stackTrace: stackTrace,
            label: '[WebSocketService] sendMessage Sink Error');
        // If send fails, potentially revert status or queue message
        if (to != null) {
          final db = DatabaseService();
          final contact = db.getContact(to);
          if (contact != null &&
              contact.lastMessageSentStatus == MessageStatus.sending) {
            contact.lastMessageSentStatus =
                MessageStatus.failed; // Or some other appropriate status
            contact.save();
            debugPrint(
                '[WebSocketService] sendMessage: Contact $to status updated to failed due to send error.');
            _messageUpdateController
                .add({'userId': to, 'type': 'status_update'});
          }
        }
        // Not rethrowing, as the primary path for disconnect handling is via stream.onError/onDone
      }
    } else {
      debugPrint(
          '[WebSocketService] sendMessage: Cannot send message, channel is null or closed.');
      // Potentially queue message or throw custom error
    }
  }

  void disconnect() {
    debugPrint(
        '[WebSocketService] disconnect: Method called. Closing channel sink.');
    try {
      _channel?.sink.close();
      debugPrint('[WebSocketService] disconnect: Sink closed.');
    } catch (e, stackTrace) {
      debugPrint('[WebSocketService] disconnect: ERROR closing sink: $e');
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] disconnect Sink Close Error');
    }
    _channel = null;
    _pingTimer?.cancel();
    _currentUserId = null;
    _currentUserPseudo = null;
    _reconnectAttempts = 0; // Reset attempts on manual disconnect
    debugPrint(
        '[WebSocketService] disconnect: Channel set to null, ping timer cancelled, user info cleared, reconnect attempts reset.');
  }

  void dispose() {
    debugPrint(
        '[WebSocketService] dispose: Method called. Closing stream controller and disposing audio player.');
    _messageUpdateController.close();
    _audioPlayer.dispose();
    _pingTimer?.cancel(); // Ensure ping timer is also cancelled on dispose
    debugPrint(
        '[WebSocketService] dispose: Resources disposed and ping timer cancelled.');
  }

  void handlePlop(Map<String, dynamic> messageData,
      {bool fromExternalNotification = false}) async {
    debugPrint(
        "[WebSocketService] handlePlop: Processing plop message. Data: $messageData, FromExternalNotification: $fromExternalNotification");
    try {
      // Prioritize 'senderId' from our own sendMessage, fallback to 'from' for compatibility
      final fromUserId = messageData['senderId'] ?? messageData['from'] as String?;
      if (fromUserId == null) {
        debugPrint(
            "[WebSocketService] handlePlop: fromUserId is null (checked senderId and from). Aborting. Data: $messageData");
        return;
      }

      String messageText;
      double? latitude;
      double? longitude;

      if (messageData['payload'] is String) {
        // Backwards compatibility or simple text payload
        messageText = messageData['payload'] as String;
        debugPrint("[NotificationService] handlePlop: Received simple text payload: '$messageText'");
      } else if (messageData['payload'] is Map) {
        final payloadMap = messageData['payload'] as Map<String, dynamic>;
        messageText = payloadMap['text'] as String? ?? "Nouveau message"; // Fallback
        latitude = payloadMap['latitude'] as double?;
        longitude = payloadMap['longitude'] as double?;
        debugPrint("[NotificationService] handlePlop: Received structured payload. Text: '$messageText', Lat: $latitude, Lon: $longitude");
      } else {
        messageText = "Plop"; // Fallback for unknown payload structure
        debugPrint("[NotificationService] handlePlop: Received unknown payload structure.");
      }

      // Ensure boolean conversion is safe
      final isDefaultMessage =
          (messageData['isDefault'] == true || messageData['isDefault'] == 'true');
      final isPending = (messageData['IsPending'] == true ||
          messageData['IsPending'] ==
              'true'); // Note: 'IsPending' casing from original code
      final String? sendDateString = messageData['sendDate'] as String?;
      DateTime? sentDate;
      if (sendDateString != null) {
        sentDate = DateTime.tryParse(sendDateString);
      }
      if (sentDate == null && messageData.containsKey('timestamp')) {
        // Fallback to 'timestamp' if 'sendDate' is missing/invalid
        final dynamic ts = messageData['timestamp'];
        if (ts is String) {
          sentDate = DateTime.tryParse(ts);
        } else if (ts is int) {
          // Assuming it might be a Unix timestamp
          sentDate = DateTime.fromMillisecondsSinceEpoch(ts);
        }
      }
      sentDate ??= DateTime.now(); // Ultimate fallback

      debugPrint(
          "[WebSocketService] handlePlop: Parsed values -> fromUserId: $fromUserId, messageText: '$messageText', isDefault: $isDefaultMessage, isPending: $isPending, sentDate: $sentDate");

      // Delegate to NotificationService to handle the notification logic
      notificationService.handlePlop(
          fromUserId: fromUserId,
          messageText: messageText,
          isDefaultMessage: isDefaultMessage,
          isPending: isPending,
          sentDate: sentDate,
          fromExternalNotification: fromExternalNotification);
      debugPrint(
          "[WebSocketService] handlePlop: Delegated to notificationService.handlePlop.");
    } catch (e, stackTrace) {
      debugPrint(
          "[WebSocketService] handlePlop: ERROR processing plop: $e. Data: $messageData");
      debugPrintStack(
          stackTrace: stackTrace, label: '[WebSocketService] handlePlop Error');
    }
  }

  Future<void> stopCurrentSound() async {
    debugPrint(
        "[WebSocketService] stopCurrentSound: Attempting to stop current sound from audioPlayer.");
    try {
      await _audioPlayer.stop();
      debugPrint(
          "[WebSocketService] stopCurrentSound: AudioPlayer stopped successfully.");
    } catch (e, stackTrace) {
      debugPrint(
          "[WebSocketService] stopCurrentSound: ERROR stopping audioPlayer: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label: '[WebSocketService] stopCurrentSound Error');
    }
  }

  void ensureConnected() {
    debugPrint(
        "[WebSocketService] ensureConnected: Checking connection status.");
    if (_channel == null || _channel!.closeCode != null) {
      debugPrint(
          "[WebSocketService] ensureConnected: Connection is down (channel is null or closeCode is set: ${_channel?.closeCode}). Attempting to re-establish.");
      _reconnectAttempts =
          0; // Reset attempts for a "manual" reconnection trigger
      if (_currentUserId != null && _currentUserPseudo != null) {
        debugPrint(
            "[WebSocketService] ensureConnected: User details found. Clearing old channel and calling connect.");
        _channel = null; // Explicitly nullify before reconnecting
        connect(_currentUserId!, _currentUserPseudo!);
      } else {
        debugPrint(
            "[WebSocketService] ensureConnected: Cannot reconnect: currentUserId or currentUserPseudo is missing.");
      }
    } else {
      debugPrint(
          "[WebSocketService] ensureConnected: Connection is already active. Close code: ${_channel?.closeCode}");
    }
  }
}

// This function seems to be part of an initialization sequence outside the class
// It was present in the original context, so I'm including logs for it too.
Future<void> initializeWebSocket() async {
  debugPrint(
      "[initializeWebSocket] Global function called: Initializing WebSocket service and listener.");
  // Initialisation des services
  final webSocketService = WebSocketService(); // Gets singleton instance
  // final databaseService = DatabaseService(); // Not used in this function scope
  // final notificationService = NotificationService(); // Not directly used in this listen, but NotificationService().handlePlop is used by the class

  // Lancer l'écouteur UNE SEULE FOIS pour toute l'application
  webSocketService.messageUpdates.listen((data) {
    debugPrint(
        "[initializeWebSocket] messageUpdates.listen: Received data from stream: $data");

    // This section seems to duplicate logic from WebSocketService._handleMessageAck or _handleNewContact or handlePlop.
    // The `messageUpdates` stream in the current class design seems more for UI updates based on specific events
    // rather than re-processing raw message types.
    // If the stream is intended for generic UI updates, the data structure should reflect that.
    // If it's for re-handling messages, it might lead to duplicate processing.
    // For now, I'm logging based on the existing structure.

    final String? updateType = data['type']
        as String?; // Expecting a 'type' field to differentiate updates
    final String? userIdForUpdate = data['userId'] as String?;

    debugPrint(
        "[initializeWebSocket] messageUpdates.listen: Update type: $updateType, User ID for update: $userIdForUpdate");

    if (userIdForUpdate == 'sync_completed') {
      debugPrint(
          "[initializeWebSocket] messageUpdates.listen: Sync completed event received. UI should refresh related data.");
      // Potentially trigger UI rebuilds related to sync
    } else if (userIdForUpdate == 'new_contact_added') {
      debugPrint(
          "[initializeWebSocket] messageUpdates.listen: New contact added event received. New contact ID: ${data['newContactId']}. UI should refresh contact list.");
      // Potentially trigger UI rebuild for contact list
    } else if (updateType == 'ack' && userIdForUpdate != null) {
      debugPrint(
          "[initializeWebSocket] messageUpdates.listen: Message acknowledgement event for user $userIdForUpdate. UI should update message status.");
      // Potentially trigger UI update for this specific contact's message status
    } else if (updateType == 'status_update' && userIdForUpdate != null) {
      debugPrint(
          "[initializeWebSocket] messageUpdates.listen: Message status update event for user $userIdForUpdate. UI should update message status.");
    }
    // The original code below for `handlePlop` call inside this global listener seems problematic
    // as `handlePlop` is already called inside `_handleMessage`.
    // If `messageUpdates` stream is meant to *re-trigger* plop handling, that's a design concern.
    // I'm commenting it out as it's likely redundant or an error.
    /*
    final fromUserId = data['senderId'] ?? data['from']; // Assuming original data structure
    if (fromUserId == null) {
      debugPrint("[initializeWebSocket] messageUpdates.listen: fromUserId is null in data. Cannot call handlePlop.");
      return;
    }

    final messageText = data['payload'] as String?; // Assuming original data structure
    if (messageText == null) {
      debugPrint("[initializeWebSocket] messageUpdates.listen: payload (messageText) is null. Cannot call handlePlop.");
      return;
    }
    final bool isDefaultMessage = (data['isDefault'] == 'true' || data['isDefault'] == true);
    final bool isPending = (data['IsPending'] == 'true' || data['IsPending'] == true);
    final String? sendDateString = data['sendDate'] as String?;
    DateTime? sentDate;
    if(sendDateString != null) sentDate = DateTime.tryParse(sendDateString);
    sentDate ??= DateTime.now();


    debugPrint("[initializeWebSocket] messageUpdates.listen: Data seems to be a plop. Calling notificationService.handlePlop. fromUserId: $fromUserId, message: $messageText");
    // Directly calling notificationService.handlePlop here means the WebSocketService.handlePlop
    // which has more logic (like contact checks) might be bypassed if the stream data is a raw message.
    // This is generally not advisable. The stream should ideally carry processed/specific update events.
    NotificationService().handlePlop(
        fromUserId:fromUserId as String,
        messageText:messageText,
        isDefaultMessage: isDefaultMessage,
        isPending:isPending,
        sentDate: sentDate, // Assuming data['sendDate'] exists
        fromExternalNotification:false // This is an internal app update
    );
    */
  }, onError: (error, stackTrace) {
    debugPrint(
        "[initializeWebSocket] messageUpdates.listen: ERROR in stream: $error");
    debugPrintStack(
        stackTrace: stackTrace, label: "[initializeWebSocket] Stream Error");
  }, onDone: () {
    debugPrint("[initializeWebSocket] messageUpdates.listen: Stream is done.");
  });
  debugPrint(
      "[initializeWebSocket] Global function: WebSocket service listener attached.");
}
