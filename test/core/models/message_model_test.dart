import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('toJson returns correct map', () {
      // Arrange
      final timestamp = DateTime.parse('2025-09-24T15:09:06.319052');
      final message = MessageModel(
        id: '123',
        text: 'Hello',
        senderId: 'sender456',
        receiverId: 'receiver789',
        timestamp: timestamp,
        // senderUsername is null by default
        // status is MessageStatus.sent by default
      );

      // Act
      final result = message.toJson();

      // Assert
      final expectedMap = {
        'id': '123',
        'text': 'Hello',
        'senderId': 'sender456',
        'senderUsername': null,
        'receiverId': 'receiver789',
        'timestamp': '2025-09-24T15:09:06.319052',
        'status': 'sent',
      };

      expect(result, expectedMap);
    });

    test('fromJson returns correct MessageModel', () {
      // Arrange
      final timestamp = DateTime.parse('2025-09-24T15:09:06.319052');
      final jsonMap = {
        'id': '123',
        'text': 'Hello',
        'senderId': 'sender456',
        'senderUsername': 'sender',
        'receiverId': 'receiver789',
        'timestamp': '2025-09-24T15:09:06.319052',
        'status': 'distributed',
      };

      // Act
      final result = MessageModel.fromJson(jsonMap);

      // Assert
      expect(result.id, '123');
      expect(result.text, 'Hello');
      expect(result.senderId, 'sender456');
      expect(result.senderUsername, 'sender');
      expect(result.receiverId, 'receiver789');
      expect(result.timestamp, timestamp);
      expect(result.status, MessageStatus.distributed);
    });
  });
}
