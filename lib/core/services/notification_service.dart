import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform; // Specific import for Platform

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For debugPrint and debugPrintStack
import 'package:flutter/material.dart'; // For Colors
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'package:plop/main.dart';
import 'package:vibration/vibration.dart';

// Assuming these are defined elsewhere and imported if necessary
// (e.g., in main.dart or a navigation service)
// If not, you might need to pass navigatorKey or use a different navigation method

class NotificationService {
  // Private constructor
  NotificationService._privateConstructor() {
    debugPrint("[NotificationService] _privateConstructor: Instance created.");
  }

  // Singleton instance
  static final NotificationService _instance =
      NotificationService._privateConstructor();

  // Stream controller for message updates
  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageUpdates =>
      _messageUpdateController.stream;

  final AudioPlayer _audioPlayer = AudioPlayer();

  factory NotificationService() {
    // debugPrint("[NotificationService] factory: Returning singleton instance."); // Can be verbose
    return _instance;
  }

  // // DatabaseService instance - consider dependency injection
  // static final DatabaseService _dbService = DatabaseService();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    debugPrint(
        "[NotificationService] init: Initializing NotificationService...");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    debugPrint(
        "[NotificationService] init: AndroidInitializationSettings configured.");

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    debugPrint(
        "[NotificationService] init: DarwinInitializationSettings configured.");

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Ouvrir',
    );
    debugPrint(
        "[NotificationService] init: LinuxInitializationSettings configured.");

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );
    debugPrint(
        "[NotificationService] init: Combined InitializationSettings configured.");

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
          debugPrint(
              "[NotificationService] onDidReceiveNotificationResponse: Received local notification response. Payload: ${notificationResponse.payload}");
          if (notificationResponse.payload != null &&
              notificationResponse.payload!.isNotEmpty) {
            handleNotificationPayload(notificationResponse.payload!);
          } else {
            debugPrint(
                "[NotificationService] onDidReceiveNotificationResponse: Payload is null or empty.");
          }
        },
        // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // For background handling if needed
      );
      debugPrint(
          "[NotificationService] init: FlutterLocalNotificationsPlugin initialized.");
    } catch (e, stackTrace) {
      debugPrint(
          "[NotificationService] init: ERROR initializing FlutterLocalNotificationsPlugin: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label:
              "[NotificationService] init FlutterLocalNotificationsPlugin Error");
      // Decide if you want to rethrow or handle this error gracefully
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'plop_channel_id',
      'Plop Notifications',
      description:
          'Canal pour les notifications Plop avec un son personnalisé.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('plop'),
    );
    debugPrint(
        "[NotificationService] init: AndroidNotificationChannel 'plop_channel_id' defined.");

    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint(
          "[NotificationService] init: AndroidNotificationChannel 'plop_channel_id' created.");
    } catch (e, stackTrace) {
      debugPrint(
          "[NotificationService] init: ERROR creating AndroidNotificationChannel: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label: "[NotificationService] init AndroidNotificationChannel Error");
    }
    debugPrint(
        "[NotificationService] init: NotificationService initialization complete.");
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool isMuted = false, // If true, this notification instance will be silent
    String? payload,
  }) async {
    // No need for UserService here anymore for global mute check,
    // as that's handled by the 'isMuted' parameter passed in.
    debugPrint(
        "[NotificationService] showNotification: Title: '$title', Body: '$body', IsMuted (for this system notification): $isMuted, Payload: $payload");

    // If isMuted is true, playSound will be false.
    // If isMuted is false, playSound will be true.
    final bool playSystemSound = !isMuted;
    debugPrint(
        "[NotificationService] showNotification: playSystemSound for this notification: $playSystemSound");

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'plop_channel_id', // Ensure this channel is created with sound enabled
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
      // Sound based on playSystemSound
      playSound:
          playSystemSound, // Also control this if necessary, though channel settings are primary
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSystemSound, // Sound based on playSystemSound
      sound: playSystemSound
          ? 'plop.aiff'
          : null, // Ensure 'plop.aiff' is in your Runner/Resources
      // Adjust badge number if necessary, e.g., via a separate service or logic
      // badgeNumber: 1,
    );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
    LinuxNotificationDetails(
      defaultActionName: 'Ouvrir',
    );
    debugPrint(
        "[NotificationService] showNotification: LinuxNotificationDetails configured.");

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
    );

    if (playSystemSound) {
      // Vibration should also respect global mute and specific mute
      debugPrint(
          "[NotificationService] showNotification: Sound is enabled, checking for vibrator.");
      bool? hasVibrator = await Vibration.hasVibrator();
      debugPrint(
          "[NotificationService] showNotification: Has vibrator: $hasVibrator");
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 200);
        debugPrint(
            "[NotificationService] showNotification: Vibration triggered.");
      }
    } else {
      debugPrint(
          "[NotificationService] showNotification: Sound is muted, no vibration.");
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload ??
            'default_payload_from_showNotification', // Use provided or default payload
      );
      debugPrint(
          "[NotificationService] showNotification: Notification shown successfully.");
    } catch (e, stackTrace) {
      debugPrint(
          "[NotificationService] showNotification: ERROR showing notification: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label: "[NotificationService] showNotification Error");
    }
  }

  void handlePlop({
    String? fromUserId,
    String? messageText,
    bool? isDefaultMessage,
    bool? isPending,
    DateTime? sentDate,
    // This flag is crucial. Set it to 'false' if the message comes via WebSocket
    // when the app is in the foreground, and you want the app to handle the sound.
    // For FCM messages, this would typically be 'true' or not set (defaulting to behavior where system handles sound).
    bool fromExternalNotification =
        true, // Default to true (system plays sound)
  }) async {
    debugPrint(
        "[NotificationService] handlePlop: Processing Plop. FromUserId: $fromUserId, Message: '$messageText', IsDefault: $isDefaultMessage, IsPending: $isPending, SentDate: $sentDate, FromExternal: $fromExternalNotification");

    if (fromUserId == null) {
      debugPrint(
          "[NotificationService] handlePlop: fromUserId is null. Aborting.");
      return;
    }

    final db = DatabaseService();
    final contact = db.getContact(fromUserId);

    if (contact == null) {
      debugPrint(
          "[NotificationService] handlePlop: Contact not found for userId: $fromUserId. Aborting.");
      return;
    }
    if (contact.isBlocked ?? false) {
      debugPrint(
          "[NotificationService] handlePlop: Contact $fromUserId is blocked. Aborting.");
      return;
    }
    debugPrint(
        "[NotificationService] handlePlop: Contact found: ${contact.alias}, IsMuted (contact): ${contact.isMuted}, CustomSound: ${contact.customSoundPath}");

    final bool hasOverride = contact.defaultMessageOverride != null &&
        contact.defaultMessageOverride!.isNotEmpty;
    final String finalMessage;
    if (isDefaultMessage == true && hasOverride) {
      finalMessage = contact.defaultMessageOverride!;
      debugPrint(
          "[NotificationService] handlePlop: Using default message override: '$finalMessage'");
    } else {
      finalMessage = messageText ?? "Plop";
      debugPrint(
          "[NotificationService] handlePlop: Using provided or fallback message: '$finalMessage'");
    }

    contact.lastMessage = finalMessage;
    contact.lastMessageTimestamp = sentDate?.toLocal() ?? DateTime.now();
    try {
      await db.updateContact(contact);
      debugPrint(
          "[NotificationService] handlePlop: Contact ${contact.userId} updated in DB. LastMsg: '$finalMessage', Timestamp: ${contact.lastMessageTimestamp}");
    } catch (e, stackTrace) {
      debugPrint(
          "[NotificationService] handlePlop: ERROR updating contact in DB: $e");
      debugPrintStack(
          stackTrace: stackTrace,
          label: "[NotificationService] handlePlop DB Update Error");
    }

    final userService = UserService();
    await userService.init();
    debugPrint(
        "[NotificationService] handlePlop: UserService initialized. GlobalMute: ${userService.isGlobalMute}");

    bool isContactMutedSetting = contact.isMuted ?? false;
    bool isGlobalMuteSetting = userService.isGlobalMute;

    // Determine if sound should be played AT ALL (either by app or system)
    bool shouldAnySoundBePlayed =
        !isContactMutedSetting && !isGlobalMuteSetting;
    debugPrint(
        "[NotificationService] handlePlop: shouldAnySoundBePlayed: $shouldAnySoundBePlayed (ContactMuted: $isContactMutedSetting, GlobalMute: $isGlobalMuteSetting)");

    bool appPlayedSound = false;

    // If it's NOT from an external notification (e.g., direct WebSocket) AND sound is generally allowed
    /*if (!fromExternalNotification && shouldAnySoundBePlayed) {
      debugPrint(
          "[NotificationService] handlePlop: Conditions met for APP to play sound (not external, not muted).");
      if (contact.customSoundPath != null &&
          contact.customSoundPath!.isNotEmpty) {
        try {
          await _audioPlayer.play(DeviceFileSource(contact.customSoundPath!));
          debugPrint(
              "[NotificationService] handlePlop: App played custom sound: ${contact.customSoundPath}");

          bool? hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator ?? false) {
            Vibration.vibrate(duration: 200);
            debugPrint(
                "[NotificationService] showNotification: Vibration triggered.");
          }
          appPlayedSound = true;
        } catch (e, stackTrace) {
          debugPrint(
              "[NotificationService] handlePlop: ERROR playing custom sound: $e");
          debugPrintStack(
              stackTrace: stackTrace,
              label: "[NotificationService] handlePlop Custom Sound Error");
          // Fallback to default sound if custom sound fails
          await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
          debugPrint(
              "[NotificationService] handlePlop: App played default sound as fallback.");
          appPlayedSound = true;
        }
      } else {
        await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
        debugPrint(
            "[NotificationService] handlePlop: App played default sound 'plop.mp3'.");
        appPlayedSound = true;
      }
    } else if (fromExternalNotification) {
      debugPrint(
          "[NotificationService] handlePlop: From external source. App will NOT play sound. System notification will handle it if not muted.");
    } else if (!shouldAnySoundBePlayed) {
      debugPrint(
          "[NotificationService] handlePlop: Sound is muted (contact or global). App will NOT play sound.");
    }*/

    // Show system notification if it's not a pending message
    bool showSystemNotification = isPending == false;
    if (showSystemNotification) {
      debugPrint(
          "[NotificationService] handlePlop: Attempting to show system notification for non-pending message.");

      // System notification should be muted IF:
      // 1. The app already played the sound (because it wasn't an external notification)
      // OR 2. Sounds are generally disabled for this plop (contact mute or global mute)
      bool muteSystemNotificationSound =
          appPlayedSound || !shouldAnySoundBePlayed;

      debugPrint(
          "[NotificationService] handlePlop: muteSystemNotificationSound: $muteSystemNotificationSound (appPlayedSound: $appPlayedSound, shouldAnySoundBePlayed: $shouldAnySoundBePlayed)");

      showNotification(
        title: contact.alias,
        body: finalMessage,
        // This 'isMuted' now controls whether the *system notification* makes a sound
        isMuted: muteSystemNotificationSound,
        payload: jsonEncode({'action': 'open_chat', 'userId': fromUserId}),
      );
    } else {
      debugPrint(
          "[NotificationService] handlePlop: Not showing system notification (message is pending).");
    }

    _messageUpdateController
        .add({'userId': fromUserId, 'message': finalMessage});
    debugPrint(
        "[NotificationService] handlePlop: Message update added to stream for userId: $fromUserId.");
    debugPrint(
        "[NotificationService] handlePlop: Processing complete for Plop from $fromUserId.");
  }
}

Future<void> sendFcmTokenToServer() async {
  debugPrint(
      "[NotificationService] sendFcmTokenToServer: Attempting to send FCM token.");
  final userService = UserService();
  await userService.init();
  if (!userService.hasUser()) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: No user logged in. Aborting token send.");
    return;
  }
  debugPrint(
      "[NotificationService] sendFcmTokenToServer: User found: ${userService.userId}");

  String? token;
  try {
    token = await FirebaseMessaging.instance.getToken();
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: FCM token obtained: $token");
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: ERROR getting FCM token: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] FCM Token Get Error");
    return;
  }

  if (token == null) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: FCM token is null. Aborting.");
    return;
  }

  final url = Uri.parse('${AppConfig.baseUrl}/users/update-token');
  final headers = {'Content-Type': 'application/json; charset=UTF-8'};
  final body = jsonEncode({'userId': userService.userId, 'token': token});
  debugPrint(
      "[NotificationService] sendFcmTokenToServer: Sending token to $url. Body: $body");

  try {
    final response = await http.post(url, headers: headers, body: body);
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: Response status: ${response.statusCode}. Body: ${response.body}");
    if (response.statusCode == 200) {
      debugPrint(
          "[NotificationService] sendFcmTokenToServer: Token sent successfully.");
    } else {
      debugPrint(
          "[NotificationService] sendFcmTokenToServer: Failed to send token.");
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] sendFcmTokenToServer: NETWORK ERROR sending token: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] FCM Token Send Network Error");
  }
}

Future<LocationPermission> initializeLocationPermission() async {
  debugPrint(
      "[NotificationService] initializeLocationPermission: Starting plugin initialization.");
  // Check if location services are enabled.
  // You might want to also prompt the user to enable them if they are off,
  // but for this initial check, we focus on permission.
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint("[AppLauncher] Location services are disabled.");
    // You could return a special status or handle this to show a different screen/dialog
    // For simplicity here, we proceed to check permission, but Geolocator.requestPermission()
    // might not show a dialog if services are off.
  }
  return await Geolocator.checkPermission();
}


Future<void> initializeNotificationPlugin() async {
  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Starting plugin initialization.");
  // This function is usually called once at app startup.
  // The NotificationService().init() handles the core local notifications setup.
  // This function seems to focus more on permissions and FCM listeners.

  // Permissions Request
  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Requesting notification permissions...");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Local instance for permission request
  bool? result = false;
  try {
    if (Platform.isAndroid) {
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        result = await androidImplementation.requestNotificationsPermission();
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: Android notification permission requested. Result: $result");
      } else {
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: AndroidFlutterLocalNotificationsPlugin implementation is null.");
      }
    } else if (Platform.isIOS) {
      final iosImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        result = await iosImplementation.requestPermissions(
            alert: true, badge: true, sound: true);
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: iOS notification permission requested. Result: $result");
      } else {
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: IOSFlutterLocalNotificationsPlugin implementation is null.");
      }
    } else if (Platform.isMacOS) {
      final macOSImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      if (macOSImplementation != null) {
        result = await macOSImplementation.requestPermissions(
            alert: true, badge: true, sound: true);
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: macOS notification permission requested. Result: $result");
      } else {
        debugPrint(
            "[NotificationService] initializeNotificationPlugin: MacOSFlutterLocalNotificationsPlugin implementation is null.");
      }
    } else {
      debugPrint(
          "[NotificationService] initializeNotificationPlugin: Platform not Android, iOS, or macOS. Skipping specific permission request.");
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] initializeNotificationPlugin: ERROR requesting permissions: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] Permissions Request Error");
  }

  // Initialize FCM message listeners
  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Setting up FCM message listeners.");
  try {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '[NotificationService] FCM onMessage (foreground): Received message. Message ID: ${message.messageId}, Data: ${message.data}');
      // For foreground messages, you usually handle them by showing an in-app notification
      // or updating UI, rather than a system notification if it's disruptive.
      // The current handleNotificationTap might be too aggressive for foreground.
      // Consider a different handler or adapting handleNotificationTap.
      // For now, let's call a more specific handler for foreground:
      NotificationService().handlePlop(
          // Assuming this is the desired action
          fromUserId: message.data['fromUserId'] as String?,
          // Adjust based on your payload
          messageText:
              message.notification?.body ?? message.data['body'] as String?,
          isDefaultMessage: message.data['isDefaultMessage'] as bool?,
          isPending: message.data['isPending'] as bool? ?? false,
          // Default to not pending
          sentDate: message.sentTime,
          fromExternalNotification:
              true // It's from FCM, so it's "external" to app's direct sound play
          );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '[NotificationService] FCM onMessageOpenedApp (background tap): User tapped notification. Message ID: ${message.messageId}, Data: ${message.data}');
      handleNotificationTap(message); // This seems appropriate
    });
    debugPrint(
        "[NotificationService] initializeNotificationPlugin: FCM message listeners configured.");
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] initializeNotificationPlugin: ERROR setting up FCM listeners: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] FCM Listener Setup Error");
  }

  // Send initial token (moved from here to sendToken function, which can be called after permissions)
  // await sendToken(); // Call sendToken explicitly after this function if needed

  debugPrint(
      "[NotificationService] initializeNotificationPlugin: Plugin initialization complete.");
}

Future<void> sendToken() async {
  debugPrint(
      "[NotificationService] sendToken: Initiating FCM token sending process.");
  // This function now primarily focuses on sending the token.
  // Permissions should ideally be requested before this is called if token generation depends on them.

  // Attempt to send the current token to the server.
  await sendFcmTokenToServer();

  // Set up listener for future token refreshes.
  try {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint(
          "[NotificationService] onTokenRefresh: New FCM token detected: $newToken. Sending to server...");
      sendFcmTokenToServer(); // Re-uses the main sending logic
    });
    debugPrint(
        "[NotificationService] sendToken: FCM onTokenRefresh listener set up.");
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] sendToken: ERROR setting up onTokenRefresh listener: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] FCM onTokenRefresh Error");
  }
  debugPrint("[NotificationService] sendToken: Process complete.");
}

Future<void> checkNotificationFromTerminatedState() async {
  debugPrint(
      "[NotificationService] checkNotificationFromTerminatedState: Checking for initial message from terminated state...");
  try {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          "[NotificationService] checkNotificationFromTerminatedState: App launched from terminated state by notification. Message ID: ${initialMessage.messageId}, Data: ${initialMessage.data}");
      // Delay slightly to ensure UI is ready for navigation or processing
      // Future.delayed(Duration(milliseconds: 500), () {
      handleNotificationTap(initialMessage);
      // });
    } else {
      debugPrint(
          "[NotificationService] checkNotificationFromTerminatedState: No initial message found from terminated state.");
    }
  } catch (e, stackTrace) {
    debugPrint(
        "[NotificationService] checkNotificationFromTerminatedState: ERROR checking initial message: $e");
    debugPrintStack(
        stackTrace: stackTrace,
        label: "[NotificationService] Initial Message Check Error");
  }
}

void handleNotificationPayload(String payload) {
  debugPrint(
      "[handleNotificationPayload] Traitement du payload de notification: $payload");
  try {
    // final Map<String, dynamic> data = jsonDecode(payload);

    // if (data['action'] == 'open_chat') {
    //   final String chatId = data['chatId'];

    // Utilisation de la GlobalKey pour naviguer sans BuildContext !
    navigatorKey.currentState?.pushNamed('/');
    debugPrint("[handleNotificationPayload] Navigation vers '/' initiée.");
    // }
    // Ajoutez d'autres 'if' pour d'autres actions
  } catch (e) {
    debugPrint(
        '[handleNotificationPayload] Erreur lors du traitement du payload de notification : $e');
  }
}

/// Gère la navigation quand une notification est cliquée.
void handleNotificationTap(RemoteMessage message) {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("[handleNotificationTap] Binding Flutter assuré.");

  debugPrint(
      "[handleNotificationTap] Gestion du clic sur la notification ! Payload de données : ${message.data}");

  WebSocketService webSocketService = WebSocketService();
  debugPrint("[handleNotificationTap] Instance de WebSocketService créée.");
  webSocketService.ensureConnected();
  debugPrint("[handleNotificationTap] Connexion WebSocket assurée.");
  final DateTime? sentTimestamp = message.sentTime;
  message.data['sendDate'] = sentTimestamp;
  debugPrint(
      "[handleNotificationTap] Date d'envoi ajoutée aux données du message: $sentTimestamp");
  webSocketService.handlePlop(message.data, fromExternalNotification: true);
  debugPrint("[handleNotificationTap] Méthode handlePlop appelée.");

  // Vous pouvez ajouter d'autres 'if' pour d'autres types de notifications
}
