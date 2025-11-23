import 'package:hive_ce/hive.dart';
import 'package:plop/core/models/contact_model.dart'; // Assuming MessageStatus is here or in its own file

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  String? senderId;

  @HiveField(3)
  String? senderUsername;

  @HiveField(4)
  String? receiverId;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  MessageStatus status;

  MessageModel({
    required this.id,
    required this.text,
    this.senderId,
    this.senderUsername,
    this.receiverId,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String?,
      senderUsername: json['senderUsername'] as String?,
      receiverId: json['receiverId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.byName(json['status'] as String? ?? 'sent'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }
}

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 1;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      text: fields[1] as String,
      senderId: fields[2] as String?,
      senderUsername: fields[3] as String?,
      receiverId: fields[4] as String?,
      timestamp: fields[5] as DateTime,
      status: fields[6] as MessageStatus,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderUsername)
      ..writeByte(4)
      ..write(obj.receiverId)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status);
  }
}
