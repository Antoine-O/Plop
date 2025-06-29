import 'package:hive/hive.dart';

part 'message_model.g.dart'; // Fichier généré par Hive

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  MessageModel({required this.id, required this.text});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}
