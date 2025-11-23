import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final NotificationService _notificationService;
  WebSocketChannel? _channel;
  final DatabaseService _databaseService = DatabaseService();
  final UserService _userService = UserService();
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  final String _url = 'ws://192.168.1.10:3000';

  bool get isConnected => _isConnected;

  WebSocketService(this._notificationService) {
    if (kDebugMode) {
      print('[WebSocketService] _privateConstructor: Instance created.');
    }
  }

  void connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    if (kDebugMode) {
      print('[WebSocketService] connect: Connecting to $_url');
    }

    try {
      final user = await _userService.getUser();
      if (user == null || user.userId.isEmpty) {
        if (kDebugMode) {
          print(
              '[WebSocketService] connect: No user ID, aborting connection.');
        }
        _isConnecting = false;
        return;
      }
      final wsUrl = '$_url?userId=${user.userId}';
      _channel = IOWebSocketChannel.connect(wsUrl);
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      if (kDebugMode) {
        print('[WebSocketService] connect: Connection established.');
      }
      _listen();
      _reconnectTimer?.cancel();
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      if (kDebugMode) {
        print('[WebSocketService] connect: Connection error: $e');
      }
      _scheduleReconnect();
    }
  }

  void _listen() {
    if (kDebugMode) {
      print('[WebSocketService] _listen: Starting to listen to the channel.');
    }
    _channelSubscription?.cancel();
    _channelSubscription = _channel?.stream.listen(
      (message) {
        if (kDebugMode) {
          print('[WebSocketService] _listen: Received raw message: $message');
        }
        _handleMessage(message);
      },
      onDone: () {
        if (kDebugMode) {
          print(
              '[WebSocketService] _listen: Channel done. _isConnected: $_isConnected');
        }
        if (_isConnected) {
          _isConnected = false;
          _scheduleReconnect();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('[WebSocketService] _listen: Channel error: $error');
        }
        _isConnected = false;
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (kDebugMode) {
      print('[WebSocketService] _scheduleReconnect: Scheduling reconnection.');
    }
    final duration =
        Duration(seconds: min(pow(2, _reconnectAttempts).toInt(), 60));
    _reconnectTimer = Timer(duration, () {
      if (!_isConnected && !_isConnecting) {
        if (kDebugMode) {
          print(
              '[WebSocketService] _scheduleReconnect: Timer expired, attempting to reconnect.');
        }
        _reconnectAttempts++;
        connect();
      }
    });
  }

  void disconnect() {
    if (kDebugMode) {
      print('[WebSocketService] disconnect: Method called.');
    }
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
  }

  void dispose() {
    if (kDebugMode) {
      print('[WebSocketService] dispose: Method called.');
    }
    disconnect();
  }

  void _handleMessage(String message) {
    try {
      final decodedMessage = jsonDecode(message);
      final type = decodedMessage['type'];

      if (kDebugMode) {
        print(
            '[WebSocketService] _handleMessage: Handling message of type: $type');
      }

      switch (type) {
        case 'message':
          _handleNewMessage(decodedMessage['data']);
          break;
        case 'message-ack':
          _handleMessageAck(decodedMessage['data']);
          break;
        case 'message-status-update':
          _handleMessageStatusUpdate(decodedMessage['data']);
          break;
        case 'messages-sync':
          _handleMessagesSync(decodedMessage['data']);
          break;
        case 'contacts-sync':
          _handleContactsSync(decodedMessage['data']);
          break;
        case 'user-data-sync':
          _handleUserDataSync(decodedMessage['data']);
          break;
        default:
          if (kDebugMode) {
            print(
                '[WebSocketService] _handleMessage: Received unknown message type: $type');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocketService] _handleMessage: Error processing message: $e');
      }
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) async {
    try {
      final message = MessageModel.fromJson(data);
      if (kDebugMode) {
        print(
            '[WebSocketService] _handleNewMessage: Received message from ${message.senderId}');
      }
      await _databaseService.messagesBox.put(message.id, message);
      await _notificationService.showNotification(message);
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocketService] _handleNewMessage: Error: $e');
      }
    }
  }

  void _handleMessageAck(Map<String, dynamic> data) async {
    final tempId = data['tempId'];
    final newMessage = MessageModel.fromJson(data['newMessage']);
    if (kDebugMode) {
      print(
          '[WebSocketService] _handleMessageAck: Message acknowledged, tempId: $tempId, newId: ${newMessage.id}');
    }

    await _databaseService.messagesBox.delete(tempId);
    await _databaseService.messagesBox.put(newMessage.id, newMessage);

    if (newMessage.receiverId != null) {
      final contact =
          await _databaseService.getContact(newMessage.receiverId!);
      if (contact != null) {
        contact.lastMessageSentStatus = MessageStatus.sent;
        await contact.save();
      }
    }
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    final messageId = data['messageId'];
    final status = data['status'];
    if (kDebugMode) {
      print(
          '[WebSocketService] _handleMessageStatusUpdate: Updating status for message $messageId to $status');
    }
    final message = _databaseService.messagesBox.get(messageId);
    if (message != null) {
      message.status = MessageStatus.values.byName(status);
      await _databaseService.messagesBox.put(messageId, message);
    }
  }

  void sendMessage(String recipientId, String text, {String? tempId}) async {
    if (!_isConnected) {
      if (kDebugMode) {
        print(
            '[WebSocketService] sendMessage: Not connected. Message not sent.');
      }
      return;
    }

    final user = await _userService.getUser();
    if (user == null) {
      if (kDebugMode) {
        print(
            '[WebSocketService] sendMessage: User not found. Cannot send message.');
      }
      return;
    }
    final message = MessageModel(
      id: tempId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.userId,
      receiverId: recipientId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    await _databaseService.messagesBox.put(message.id, message);

    _channel?.sink.add(jsonEncode({
      'type': 'message',
      'data': message.toJson(),
    }));
    if (kDebugMode) {
      print('[WebSocketService] sendMessage: Message sent to $recipientId.');
    }
  }

  void syncClientData() async {
    if (kDebugMode) {
      print('[WebSocketService] syncClientData: Starting data sync.');
    }
    final messages = _databaseService.messagesBox.values.toList();
    final contacts = _databaseService.contactsBox.values.toList();

    _channel?.sink.add(jsonEncode({
      'type': 'sync-client-data',
      'data': {
        'messages': messages.map((m) => m.toJson()).toList(),
        'contacts': contacts.map((c) => c.toJson()).toList(),
      }
    }));
    if (kDebugMode) {
      print(
          '[WebSocketService] syncClientData: Sync request sent with ${messages.length} messages and ${contacts.length} contacts.');
    }
  }

  void requestSync() {
    if (!_isConnected) {
      if (kDebugMode) {
        print(
            '[WebSocketService] requestSync: Not connected. Cannot request sync.');
      }
      return;
    }
    _channel?.sink.add(jsonEncode({'type': 'request-sync'}));
    if (kDebugMode) {
      print('[WebSocketService] requestSync: Sync request sent to server.');
    }
  }

  void _handleMessagesSync(List<dynamic> messagesData) async {
    try {
      final messages =
          messagesData.map((data) => MessageModel.fromJson(data)).toList();
      if (kDebugMode) {
        print(
            '[WebSocketService] _handleMessagesSync: Received ${messages.length} messages to sync.');
      }
      for (var message in messages) {
        await _databaseService.messagesBox.put(message.id, message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocketService] _handleMessagesSync: Error: $e');
      }
    }
  }

  void _handleContactsSync(List<dynamic> contactsData) async {
    try {
      final contacts =
          contactsData.map((data) => Contact.fromJson(data)).toList();
      if (kDebugMode) {
        print(
            '[WebSocketService] _handleContactsSync: Received ${contacts.length} contacts to sync.');
      }
      for (var contact in contacts) {
        await _databaseService.contactsBox.put(contact.userId, contact);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocketService] _handleContactsSync: Error: $e');
      }
    }
  }

  void _handleUserDataSync(Map<String, dynamic> data) async {
    if (kDebugMode) {
      print(
          '[WebSocketService] _handleUserDataSync: Received user data to sync.');
    }
    if (data['contacts'] != null) {
      final contacts = (data['contacts'] as List)
          .map((c) => Contact.fromJson(c))
          .toList();
      await _mergeContacts(contacts);
    }
    if (data['messages'] != null) {
      final messages = (data['messages'] as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
      await _mergeMessages(messages);
    }
  }

  Future<void> _mergeContacts(List<Contact> newContacts) async {
    if (kDebugMode) {
      print(
          '[WebSocketService] _mergeContacts: Merging ${newContacts.length} contacts.');
    }
    for (var contact in newContacts) {
      await _databaseService.contactsBox.put(contact.userId, contact);
    }
  }

  Future<void> _mergeMessages(List<MessageModel> newMessages) async {
    if (kDebugMode) {
      print(
          '[WebSocketService] _mergeMessages: Merging ${newMessages.length} messages.');
    }
    for (var message in newMessages) {
      await _databaseService.messagesBox.put(message.id, message);
    }
  }

  void sendReadConfirmation(String messageId) {
    if (!_isConnected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'read-confirmation',
      'data': {'messageId': messageId}
    }));
    if (kDebugMode) {
      print(
          '[WebSocketService] sendReadConfirmation: Sent read confirmation for message $messageId.');
    }
  }

  Future<void> updateContactLastMessageStatus(
      String contactId, MessageStatus status) async {
    final contact = await _databaseService.getContact(contactId);
    if (contact != null) {
      contact.lastMessageSentStatus = status;
      contact.lastMessageSentTimestamp = DateTime.now();
      await contact.save();
    }
  }

  Future<void> checkSentMessageStatus(String contactId) async {
    final contact = await _databaseService.getContact(contactId);
    if (contact != null) {
      if (contact.lastMessageSentStatus == MessageStatus.sending) {
        contact.lastMessageSentStatus = MessageStatus.failed;
        await contact.save();
      }
    }
  }
}
