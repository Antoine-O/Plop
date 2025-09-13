import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

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
    return _instance;
  }

  WebSocketChannel? _channel;
  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;

  Stream<Map<String, dynamic>> get messageUpdates =>
      _messageUpdateController.stream;
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  int _reconnectAttempts = 0;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  void _updateConnectionStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
    debugPrint('[WebSocketService] Connection status updated to: $status');
  }

  void _handleDisconnect() {
    debugPrint(
        '[WebSocketService] _handleDisconnect: WebSocket disconnected. Current reconnect attempts: $_reconnectAttempts');
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _updateConnectionStatus(ConnectionStatus.reconnecting);

    if (_reconnectAttempts < 10) {
      // Limit to 10 attempts for exponential backoff
      _reconnectAttempts++;
      // Exponential backoff with jitter
      final delay = Duration(
          seconds: pow(2, _reconnectAttempts).toInt() + Random().nextInt(5));

      debugPrint(
          '[WebSocketService] _handleDisconnect: Will attempt reconnection (attempt #$_reconnectAttempts) in $delay seconds.');

      Future.delayed(delay, () {
        debugPrint(
            '[WebSocketService] _handleDisconnect: Attempting reconnection #$_reconnectAttempts...');
        if (_currentUserId != null && _currentUserPseudo != null) {
          connect(_currentUserId!, _currentUserPseudo!);
        } else {
          debugPrint(
              '[WebSocketService] _handleDisconnect: Cannot reconnect, currentUserId or currentUserPseudo is null.');
          _updateConnectionStatus(ConnectionStatus.disconnected);
        }
      });
    } else {
      debugPrint(
          '[WebSocketService] _handleDisconnect: Maximum reconnection attempts reached. Stopping reconnection attempts.');
      _updateConnectionStatus(ConnectionStatus.disconnected);
      // Optionally inform the user
    }
  }

  void connect(String userId, String userPseudo) {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      debugPrint(
          '[WebSocketService] connect: Already connected or connecting. Aborting.');
      return;
    }

    _updateConnectionStatus(ConnectionStatus.connecting);
    _currentUserId = userId;
    _currentUserPseudo = userPseudo;

    try {
      final uri =
          Uri.parse('$_baseUrl/connect?userId=$userId&pseudo=$userPseudo');
      debugPrint('[WebSocketService] connect: Connecting to URI: $uri');
      _channel = WebSocketChannel.connect(uri);
      _updateConnectionStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0; // Reset on successful connection
      debugPrint(
          '[WebSocketService] connect: WebSocketChannel created. Listening to stream.');

      _channel!.stream.listen(
        (message) {
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

      _startPing();
    } catch (e, stackTrace) {
      debugPrint(
          '[WebSocketService] connect: ERROR during connection attempt: $e');
      debugPrintStack(
          stackTrace: stackTrace, label: '[WebSocketService] connect Error');
      _handleDisconnect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_status == ConnectionStatus.connected) {
        final Map<String, dynamic> pingData = {
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        };
        final String jsonPing = jsonEncode(pingData);
        debugPrint('[WebSocketService] _startPing: Sending ping: $jsonPing');
        try {
          _channel!.sink.add(jsonPing);
          // Start a timer to wait for a pong
          _pongTimeoutTimer?.cancel();
          _pongTimeoutTimer = Timer(const Duration(seconds: 5), () {
            debugPrint(
                "[WebSocketService] Pong timeout! Didn't receive a pong in time.");
            _handleDisconnect();
          });
        } catch (e, stackTrace) {
          debugPrint('[WebSocketService] _startPing: ERROR sending ping: $e');
          debugPrintStack(
              stackTrace: stackTrace,
              label: '[WebSocketService] _startPing Error');
          _handleDisconnect(); // Trigger reconnect if ping fails
        }
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message);
      final String type = decoded['type'];
      debugPrint(
          '[WebSocketService] _handleMessage: Decoded message type: $type.');

      if (type == 'pong') {
        _pongTimeoutTimer?.cancel();
        debugPrint("[WebSocketService] Pong received!");
        return; // Handled, no further processing needed
      }

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
          _handleSyncRequest();
          break;
        case 'sync_data_broadcast':
          _handleSyncDataBroadcast(decoded['payload']);
          break;
        default:
          debugPrint(
              '[WebSocketService] _handleMessage: Unknown message type: $type.');
      }
    } catch (e, stackTrace) {
      debugPrint(
          '[WebSocketService] _handleMessage: ERROR processing message: $e.');
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
    ensureConnected();
    if (_status == ConnectionStatus.connected) {
      final message = {
        'type': type,
        'to': to,
        'payload': payload,
        'isDefault': isDefault,
        'senderId': _currentUserId,
        'senderPseudo': _currentUserPseudo,
        'sendDate': DateTime.now().toIso8601String(),
      };
      final jsonMessage = jsonEncode(message);

      try {
        _channel!.sink.add(jsonMessage);
        debugPrint(
            '[WebSocketService] sendMessage: Message added to sink. Type: $type, To: $to');
        if (to != null) {
          final db = DatabaseService();
          final contact = db.getContact(to);
          if (contact != null) {
            contact.lastMessageSentStatus = MessageStatus.sending;
            contact.lastMessageSentTimestamp = DateTime.now();
            contact.save();
            _messageUpdateController
                .add({'userId': to, 'type': 'status_update'});
          }
        }
      } catch (e, stackTrace) {
        debugPrint("[WebSocketService] sendMessage: ERROR sending message: $e");
        debugPrintStack(
            stackTrace: stackTrace,
            label: '[WebSocketService] sendMessage Sink Error');
        if (to != null) {
          final db = DatabaseService();
          final contact = db.getContact(to);
          if (contact != null &&
              contact.lastMessageSentStatus == MessageStatus.sending) {
            contact.lastMessageSentStatus = MessageStatus.failed;
            contact.save();
            _messageUpdateController
                .add({'userId': to, 'type': 'status_update'});
          }
        }
      }
    } else {
      debugPrint(
          '[WebSocketService] sendMessage: Cannot send message, channel is not connected.');
    }
  }

  void disconnect() {
    debugPrint('[WebSocketService] disconnect: Method called.');
    _reconnectAttempts = 0; // Reset on manual disconnect
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _currentUserId = null;
    _currentUserPseudo = null;
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    debugPrint('[WebSocketService] dispose: Method called.');
    _messageUpdateController.close();
    _connectionStatusController.close();
    _audioPlayer.dispose();
    disconnect();
  }

  void handlePlop(Map<String, dynamic> messageData) async {
    bool fromExternalNotification = false;
    debugPrint(
        "[WebSocketService] handlePlop: Processing plop message. Data: $messageData, FromExternalNotification: $fromExternalNotification");
    try {
      // Prioritize 'senderId' from our own sendMessage, fallback to 'from' for compatibility
      final fromUserId =
          messageData['senderId'] ?? messageData['from'] as String?;
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
        debugPrint(
            "[NotificationService] handlePlop: Received simple text payload: '$messageText'");
      } else if (messageData['payload'] is Map) {
        final payloadMap = messageData['payload'] as Map<String, dynamic>;
        messageText =
            payloadMap['text'] as String? ?? "Nouveau message"; // Fallback
        latitude = payloadMap['latitude'] as double?;
        longitude = payloadMap['longitude'] as double?;
        debugPrint(
            "[NotificationService] handlePlop: Received structured payload. Text: '$messageText', Lat: $latitude, Lon: $longitude");
      } else {
        messageText = "Plop"; // Fallback for unknown payload structure
        debugPrint(
            "[NotificationService] handlePlop: Received unknown payload structure.");
      }

      // Ensure boolean conversion is safe
      final isDefaultMessage = (messageData['isDefault'] == true ||
          messageData['isDefault'] == 'true');
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
    if (_status != ConnectionStatus.connected) {
      debugPrint(
          "[WebSocketService] ensureConnected: Connection is down. Attempting to re-establish.");
      _reconnectAttempts = 0; // Reset for a "manual" trigger
      if (_currentUserId != null && _currentUserPseudo != null) {
        connect(_currentUserId!, _currentUserPseudo!);
      } else {
        debugPrint(
            "[WebSocketService] ensureConnected: Cannot reconnect: user details missing.");
      }
    } else {
      debugPrint(
          "[WebSocketService] ensureConnected: Connection is active.");
    }
  }
}

Future<void> initializeWebSocket() async {
  debugPrint(
      "[initializeWebSocket] Global function called: Initializing WebSocket service and listener.");
  final webSocketService = WebSocketService();

  webSocketService.messageUpdates.listen((data) {
    debugPrint(
        "[initializeWebSocket] messageUpdates.listen: Received data from stream: $data");
  }, onError: (error, stackTrace) {
    debugPrint(
        "[initializeWebSocket] messageUpdates.listen: ERROR in stream: $error");
    debugPrintStack(
        stackTrace: stackTrace, label: "[initializeWebSocket] Stream Error");
  }, onDone: () {
    debugPrint("[initializeWebSocket] messageUpdates.listen: Stream is done.");
  });

  webSocketService.connectionStatus.listen((status) {
    debugPrint(
        "[initializeWebSocket] connectionStatus.listen: Connection status changed to: $status");
    // You can add logic here to react to connection status changes in your UI
  });

  debugPrint(
      "[initializeWebSocket] Global function: WebSocket service listeners attached.");
}
