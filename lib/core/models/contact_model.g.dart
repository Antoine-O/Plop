// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 0;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      userId: fields[0] as String,
      originalPseudo: fields[1] as String,
      alias: fields[2] as String,
      colorValue: fields[3] as int,
      isMuted: fields[4] as bool?,
      type: fields[5] as String,
      lastMessage: fields[6] as String?,
      lastMessageTimestamp: fields[7] as DateTime?,
      isBlocked: fields[8] as bool?,
      customSoundPath: fields[9] as String?,
      defaultMessageOverride: fields[10] as String?,
      isHidden: fields[11] as bool?,
      lastMessageSentTimestamp: fields[12] as DateTime?,
      lastMessageSent: fields[13] as String?,
      lastMessageSentDefault: fields[14] as bool?,
      lastMessageSentStatus: fields[15] as MessageStatus?,
      lastMessageSentError: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.originalPseudo)
      ..writeByte(2)
      ..write(obj.alias)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isMuted)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.lastMessage)
      ..writeByte(7)
      ..write(obj.lastMessageTimestamp)
      ..writeByte(8)
      ..write(obj.isBlocked)
      ..writeByte(9)
      ..write(obj.customSoundPath)
      ..writeByte(10)
      ..write(obj.defaultMessageOverride)
      ..writeByte(11)
      ..write(obj.isHidden)
      ..writeByte(12)
      ..write(obj.lastMessageSentTimestamp)
      ..writeByte(13)
      ..write(obj.lastMessageSent)
      ..writeByte(14)
      ..write(obj.lastMessageSentDefault)
      ..writeByte(15)
      ..write(obj.lastMessageSentStatus)
      ..writeByte(16)
      ..write(obj.lastMessageSentError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 2;

  @override
  MessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageStatus.sending;
      case 1:
        return MessageStatus.sent;
      case 2:
        return MessageStatus.distributed;
      case 3:
        return MessageStatus.acknowledged;
      case 4:
        return MessageStatus.failed;
      case 5:
        return MessageStatus.unknown;
      default:
        return MessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    switch (obj) {
      case MessageStatus.sending:
        writer.writeByte(0);
        break;
      case MessageStatus.sent:
        writer.writeByte(1);
        break;
      case MessageStatus.distributed:
        writer.writeByte(2);
        break;
      case MessageStatus.acknowledged:
        writer.writeByte(3);
        break;
      case MessageStatus.failed:
        writer.writeByte(4);
        break;
      case MessageStatus.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
