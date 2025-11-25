import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
// import 'package:plop/core/services/websocket_service.dart';
// import 'package:plop/main.dart';
import 'package:vibration/vibration.dart';

// A data class to safely parse notification payloads.
class _PlopNotification {
  final String? fromUserId;
  final String? messageText;
  final bool isDefaultMessage;
  final bool isPending;
  final DateTime? sentDate;

  _PlopNotification({
    required this.fromUserId,
    required this.messageText,
    required this.isDefaultMessage,
    required this.isPending,
    required this.sentDate,
  });

  factory _PlopNotification.fromRemoteMessage(RemoteMessage message) {
    // Safely parse 'isDefaultMessage'
    bool defaultMessage = false;
    if (message.data['isDefaultMessage'] is bool) {
      defaultMessage = message.data['isDefaultMessage'];
    } else if (message.data['isDefaultMessage'] is String) {
      defaultMessage =
          (message.data['isDefaultMessage'] as String).toLowerCase() == 'true';
    }

    // Safely parse 'isPending'
    bool pending = false;
    if (message.data['isPending'] is bool) {
      pending = message.data['isPending'];
    } else if (message.data['isPending'] is String) {
      pending = (message.data['isPending'] as String).toLowerCase() == 'true';
    }

    return _PlopNotification(
      fromUserId: message.data['senderId'] ?? message.data['from'] as String?,
      messageText: message.notification?.body ??
          message.data['body'] ??
          message.data['text'] as String?,
      isDefaultMessage: defaultMessage,
      isPending: pending,
      sentDate: message.sentTime,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal(
    DatabaseService(),
    UserService(),
    FlutterLocalNotificationsPlugin(),
    AudioPlayer(),
  );

  factory NotificationService() {
    return _instance;
  }

  final DatabaseService _db;
  final UserService _userService;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final AudioPlayer _audioPlayer;

  NotificationService._internal(
    this._db,
    this._userService,
    this._flutterLocalNotificationsPlugin,
    this._audioPlayer,
  );

  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageUpdates =>
      _messageUpdateController.stream;

  Future<void> init() async {
    debugPrint("[NotificationService] init: Initializing...");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Ouvrir');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        if (notificationResponse.payload != null &&
            notificationResponse.payload!.isNotEmpty) {
          handleNotificationPayload(notificationResponse.payload!);
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'plop_channel_id',
      'Plop Notifications',
      description:
          'Canal pour les notifications Plop avec un son personnalisé.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('plop'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint("[NotificationService] init: Initialization complete.");
  }

  /// Properly disposes of resources. Call this if the service is ever destroyed.
  @override
  void dispose() {
    debugPrint("[NotificationService] dispose: Cleaning up resources.");
    _messageUpdateController.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool isMuted = false,
    String? payload,
  }) async {
    final bool playSystemSound = !isMuted;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'plop_channel_id',
      'Plop Notifications',
      channelDescription: 'Canal pour les notifications Plop.',
      priority: Priority.high,
      importance: Importance.max,
      showWhen: false,
      color: Colors.transparent,
      icon: "@mipmap/ic_launcher",
      sound: playSystemSound
          ? const RawResourceAndroidNotificationSound('plop')
          : null,
      playSound: playSystemSound,
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSystemSound,
      sound: playSystemSound ? 'plop.aiff' : null,
    );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
    );

    if (playSystemSound) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    }

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Centralized message handler to avoid code duplication.
  void _handleRemoteMessage(RemoteMessage message,
      {bool fromBackground = false}) {
    debugPrint(
        "[NotificationService] _handleRemoteMessage: Processing message from ${fromBackground ? 'background' : 'foreground'}.");
    final plop = _PlopNotification.fromRemoteMessage(message);
    handlePlop(
      fromUserId: plop.fromUserId,
      messageText: plop.messageText,
      isDefaultMessage: plop.isDefaultMessage,
      isPending: plop.isPending,
      sentDate: plop.sentDate,
      fromExternalNotification: true,
    );
  }

  Future<void> handlePlop({
    String? fromUserId,
    String? messageText,
    bool? isDefaultMessage,
    bool? isPending,
    DateTime? sentDate,
    bool fromExternalNotification = true,
  }) async {
    if (fromUserId == null) {
      debugPrint("[NotificationService] handlePlop: fromUserId is null.");
      return;
    }

    final contact = _db.getContact(fromUserId);

    if (contact == null || (contact.isBlocked ?? false)) {
      debugPrint(
          "[NotificationService] handlePlop: Contact not found or is blocked for userId: $fromUserId.");
      return;
    }

    final bool hasOverride = contact.defaultMessageOverride != null &&
        contact.defaultMessageOverride!.isNotEmpty;
    final String finalMessage = (isDefaultMessage == true && hasOverride)
        ? contact.defaultMessageOverride!
        : (messageText ?? "Plop");

    contact.lastMessage = finalMessage;
    contact.lastMessageTimestamp = sentDate?.toLocal() ?? DateTime.now();
    await _db.updateContact(contact);

    // Use the already initialized singleton instance of UserService
    final bool isContactMuted = contact.isMuted ?? false;
    final bool isGlobalMute = _userService.isGlobalMute;
    final bool shouldPlaySound = !isContactMuted && !isGlobalMute;

    bool appPlayedSound = false;
    if (!fromExternalNotification && shouldPlaySound) {
      // Logic for playing sound from within the app (e.g., via WebSocket)
      try {
        if (contact.customSoundPath != null &&
            contact.customSoundPath!.isNotEmpty) {
          await _audioPlayer.play(DeviceFileSource(contact.customSoundPath!));
        } else {
          await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
        }
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        }
        appPlayedSound = true;
      } catch (e, stackTrace) {
        debugPrint(
            "[NotificationService] handlePlop: Error playing sound: $e");
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (isPending != true) {
      final bool muteSystemNotification = appPlayedSound || !shouldPlaySound;
      showNotification(
        title: contact.alias,
        body: finalMessage,
        isMuted: muteSystemNotification,
        payload: jsonEncode({'action': 'open_chat', 'userId': fromUserId}),
      );
    }

    _messageUpdateController
        .add({'userId': fromUserId, 'message': finalMessage});
    notifyListeners();
  }
}

// Top-level functions for FCM handlers

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("[FCM] Handling a background message: ${message.messageId}");
  // No need to initialize Firebase here if it's done in main.dart
  NotificationService()._handleRemoteMessage(message, fromBackground: true);
}

Future<void> initializeNotificationPlugin() async {
  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Initializing...");
  final service = NotificationService();
  await service.init(); // Initialize the service instance

  // Request permissions
  try {
    if (Platform.isAndroid) {
      await service._flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await service._flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] initializeNotificationPlugin: Error requesting permissions: $e");
    debugPrintStack(stackTrace: stackTrace);
  }

  // Set up FCM listeners
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
        '[NotificationService] FCM onMessage (foreground): Received message.');
    service._handleRemoteMessage(message, fromBackground: false);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
        '[NotificationService] FCM onMessageOpenedApp (background tap): User tapped notification.');
    service._handleRemoteMessage(message, fromBackground: true);
  });

  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Setup complete.");
}

Future<void> sendFcmTokenToServer() async {
  final userService = UserService(); // Assuming UserService is a singleton
  if (!userService.hasUser()) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: No user, aborting.");
    return;
  }

  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint(
          "[NotificationService] sendFcmTokenToServer: FCM token is null.");
      return;
    }

    final url = Uri.parse('${AppConfig.baseUrl}/users/update-token');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({'userId': userService.userId, 'token': token});

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      debugPrint(
          "[NotificationService] sendFcmTokenToServer: Token sent successfully.");
    } else {
      debugPrint(
          "[NotificationService] sendFcmTokenToServer: Failed to send token, status: ${response.statusCode}.");
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: Network error: $e");
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> sendToken() async {
  await sendFcmTokenToServer(); // Send the current token
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint(
        "[NotificationService] onTokenRefresh: New FCM token detected. Sending to server...");
    sendFcmTokenToServer(); // Send the refreshed token
  });
}

Future<void> checkNotificationFromTerminatedState() async {
  try {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          "[NotificationService] checkNotificationFromTerminatedState: App launched from notification.");
      // Using a short delay to ensure the UI is ready for any navigation.
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationService()
            ._handleRemoteMessage(initialMessage, fromBackground: true);
      });
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] checkNotificationFromTerminatedState: Error checking initial message: $e");
    debugPrintStack(stackTrace: stackTrace);
  }
}

void handleNotificationPayload(String payload) {
  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    if (data['action'] == 'open_chat' && data.containsKey('userId')) {
      // You can use this to navigate to the specific chat screen.
      // Example: navigatorKey.currentState?.pushNamed('/chat', arguments: data['userId']);
      debugPrint(
          "[handleNotificationPayload] Received action to open chat for user: ${data['userId']}");
    }
  } catch (e) {
    debugPrint(
        '[handleNotificationPayload] Error parsing notification payload: $e');
  }
}
