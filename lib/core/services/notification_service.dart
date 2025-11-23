
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';


class NotificationService {
  final DatabaseService _databaseService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService(
    this._databaseService,
    this._localNotifications,
  );

  NotificationService.test(
    this._databaseService,
    this._localNotifications,
  );

  Future<void> init() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {},
    );
  }

  Future<void> checkNotificationFromTerminatedState() async {}

  Future<void> sendFcmTokenToServer(String token) async {}

  Future<void> showNotification(MessageModel message) async {
    Contact? contact;
    if (message.senderId != null) {
      contact = await _databaseService.getContact(message.senderId!);
    }
    final title = contact?.alias ?? message.senderUsername ?? 'New Message';
    final body = message.text;

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'plop_channel_id',
      'Plop Messages',
      channelDescription: 'Channel for Plop message notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Using a consistent integer ID for the notification.
    // The message ID is a string, so we parse it to an int.
    // We use the last 4 digits to avoid potential integer overflow.
    final numericId = int.tryParse(message.id.substring(message.id.length - 4)) ?? message.hashCode;


    await _localNotifications.show(
      numericId, 
      title,
      body,
      platformChannelSpecifics,
      payload: message.senderId,
    );
  }
}
