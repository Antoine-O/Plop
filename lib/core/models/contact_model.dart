import 'package:hive/hive.dart';
part 'contact_model.g.dart';

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
  });
}
