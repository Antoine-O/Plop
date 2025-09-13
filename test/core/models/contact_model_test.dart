
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/models/contact_model.dart';

void main() {
  group('Contact', () {
    final now = DateTime.now();
    final contactJson = {
      'userId': '123',
      'originalPseudo': 'John Doe',
      'alias': 'Johnny',
      'colorValue': 4282339839,
      'isMuted': true,
      'type': 'friend',
      'lastMessage': 'Hello',
      'lastMessageTimestamp': now.toIso8601String(),
      'isBlocked': false,
      'customSoundPath': '/sounds/plop.mp3',
      'defaultMessageOverride': 'Hi there!',
      'isHidden': true,
      'lastMessageSentTimestamp': now.toIso8601String(),
      'lastMessageSent': 'Hi',
      'lastMessageSentDefault': true,
      'lastMessageSentStatus': 'sent',
      'lastMessageSentError': 'None',
    };

    final contact = Contact(
      userId: '123',
      originalPseudo: 'John Doe',
      alias: 'Johnny',
      colorValue: 4282339839,
      isMuted: true,
      type: 'friend',
      lastMessage: 'Hello',
      lastMessageTimestamp: now,
      isBlocked: false,
      customSoundPath: '/sounds/plop.mp3',
      defaultMessageOverride: 'Hi there!',
      isHidden: true,
      lastMessageSentTimestamp: now,
      lastMessageSent: 'Hi',
      lastMessageSentDefault: true,
      lastMessageSentStatus: MessageStatus.sent,
      lastMessageSentError: 'None',
    );

    test('fromJson creates a valid Contact object', () {
      final contactFromJson = Contact.fromJson(contactJson);

      expect(contactFromJson.userId, contact.userId);
      expect(contactFromJson.originalPseudo, contact.originalPseudo);
      expect(contactFromJson.alias, contact.alias);
      expect(contactFromJson.colorValue, contact.colorValue);
      expect(contactFromJson.isMuted, contact.isMuted);
      expect(contactFromJson.type, contact.type);
      expect(contactFromJson.lastMessage, contact.lastMessage);
      expect(contactFromJson.lastMessageTimestamp, contact.lastMessageTimestamp);
      expect(contactFromJson.isBlocked, contact.isBlocked);
      expect(contactFromJson.customSoundPath, contact.customSoundPath);
      expect(contactFromJson.defaultMessageOverride, contact.defaultMessageOverride);
      expect(contactFromJson.isHidden, contact.isHidden);
      expect(contactFromJson.lastMessageSentTimestamp, contact.lastMessageSentTimestamp);
      expect(contactFromJson.lastMessageSent, contact.lastMessageSent);
      expect(contactFromJson.lastMessageSentDefault, contact.lastMessageSentDefault);
      expect(contactFromJson.lastMessageSentStatus, contact.lastMessageSentStatus);
      expect(contactFromJson.lastMessageSentError, contact.lastMessageSentError);
    });

    test('toJson creates a valid JSON map', () {
      final jsonFromContact = contact.toJson();

      expect(jsonFromContact, contactJson);
    });
  });

  group('MessageStatus', () {
    test('toJson returns the correct string representation', () {
      expect(MessageStatus.sending.toJson(), 'sending');
      expect(MessageStatus.sent.toJson(), 'sent');
      expect(MessageStatus.distributed.toJson(), 'distributed');
      expect(MessageStatus.acknowledged.toJson(), 'acknowledged');
      expect(MessageStatus.failed.toJson(), 'failed');
      expect(MessageStatus.unknown.toJson(), 'unknown');
    });

    test('fromJson returns the correct MessageStatus enum', () {
      expect(MessageStatus.fromJson('sending'), MessageStatus.sending);
      expect(MessageStatus.fromJson('sent'), MessageStatus.sent);
      expect(MessageStatus.fromJson('distributed'), MessageStatus.distributed);
      expect(MessageStatus.fromJson('acknowledged'), MessageStatus.acknowledged);
      expect(MessageStatus.fromJson('failed'), MessageStatus.failed);
      expect(MessageStatus.fromJson('unknown'), MessageStatus.unknown);
      expect(MessageStatus.fromJson('invalid'), MessageStatus.unknown);
    });
  });
}
