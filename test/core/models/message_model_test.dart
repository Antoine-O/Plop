
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/models/message_model.dart';

void main() {
  group('MessageModel', () {
    final messageJson = {
      'id': '123',
      'text': 'Hello',
    };

    final message = MessageModel(
      id: '123',
      text: 'Hello',
    );

    test('fromJson creates a valid MessageModel object', () {
      final messageFromJson = MessageModel.fromJson(messageJson);

      expect(messageFromJson.id, message.id);
      expect(messageFromJson.text, message.text);
    });

    test('toJson creates a valid JSON map', () {
      final jsonFromMessage = message.toJson();

      expect(jsonFromMessage, messageJson);
    });
  });
}
