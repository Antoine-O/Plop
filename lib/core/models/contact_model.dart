import 'package:hive/hive.dart';
part 'contact_model.g.dart';
@HiveType(typeId: 2) // IMPORTANT: Use a typeId that is not used by any other type
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  @HiveField(2)
  distributed,

  @HiveField(3)
  acknowledged,

  @HiveField(4)
  failed
}
@HiveType(typeId: 0)
class Contact extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  String originalPseudo;
  @HiveField(2)
  String alias;
  @HiveField(3)
  int colorValue;
  @HiveField(4)
  bool? isMuted; // CORRECTION: Rendu nullable
  @HiveField(5)
  String type;
  @HiveField(6)
  String? lastMessage;
  @HiveField(7)
  DateTime? lastMessageTimestamp;

  // NOUVEAUX CHAMPS
  @HiveField(8)
  bool? isBlocked; // CORRECTION: Rendu nullable
  @HiveField(9)
  String? customSoundPath;
  @HiveField(10)
  String? defaultMessageOverride;
  @HiveField(11) // NOUVEAU
  bool? isHidden;
  @HiveField(12)
  DateTime? lastMessageSentTimestamp;
  @HiveField(13)
  String? lastMessageSent;
  @HiveField(14)
  bool? lastMessageSentDefault;
  @HiveField(15)
  MessageStatus? lastMessageSentStatus;
  @HiveField(16)
  String? lastMessageSentError;


  Contact({
    required this.userId,
    required this.originalPseudo,
    required this.alias,
    required this.colorValue,
    this.isMuted = false,
    this.type = 'user',
    this.lastMessage,
    this.lastMessageTimestamp,
    this.isBlocked = false,
    this.customSoundPath,
    this.defaultMessageOverride,
    this.isHidden = false, // NOUVEAU
    this.lastMessageSentTimestamp,
    this.lastMessageSent,
    this.lastMessageSentDefault,
    this.lastMessageSentStatus,
    this.lastMessageSentError
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      userId: json['userId'],
      originalPseudo: json['originalPseudo'],
      alias: json['alias'],
      colorValue: json['colorValue'],
      isMuted: json['isMuted'] ?? false,
      type: json['type'] ?? 'user',
      lastMessage: json['lastMessage'],
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'])
          : null,
      isBlocked: json['isBlocked'] ?? false,
      customSoundPath: json['customSoundPath'],
      defaultMessageOverride: json['defaultMessageOverride'],
      isHidden: json['isHidden'] ?? false,
      lastMessageSentTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'])
          : null,
      lastMessageSent: json['lastMessageSent'],
      lastMessageSentDefault: json['lastMessageSentDefault'],
      lastMessageSentStatus: json['lastMessageSentStatus'],
      lastMessageSentError: json['lastMessageSentError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'originalPseudo': originalPseudo,
      'alias': alias,
      'colorValue': colorValue,
      'isMuted': isMuted,
      'type': type,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
      'isBlocked': isBlocked,
      'customSoundPath': customSoundPath,
      'defaultMessageOverride': defaultMessageOverride,
      'isHidden': isHidden,
      'lastMessageSentTimestamp': lastMessageTimestamp?.toIso8601String(),
      'lastMessageSent': lastMessageSent,
      'lastMessageSentDefault': lastMessageSentDefault,
      'lastMessageSentStatus': lastMessageSentStatus,
      'lastMessageSentError': lastMessageSentError,
    };
  }
}
