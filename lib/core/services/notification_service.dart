import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Pour jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'package:plop/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:plop/core/config/app_config.dart';

import 'package:vibration/vibration.dart';

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService _instance =
      NotificationService._privateConstructor();
  final _messageUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final AudioPlayer _audioPlayer = AudioPlayer();

  factory NotificationService() => _instance;
  static final DatabaseService _dbService = DatabaseService();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuration pour Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration pour iOS et macOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuration pour Linux
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Ouvrir',
    );

    // Regrouper toutes les configurations spécifiques à chaque plateforme
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Définition du canal
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'plop_channel_id', // un ID unique pour le canal
      'Plop Notifications', // Nom visible par l'utilisateur
      description:
          'Canal pour les notifications Plop avec un son personnalisé.',
      importance: Importance.max,
      playSound: true, // Très important
      sound: RawResourceAndroidNotificationSound(
          'plop'), // Nom du fichier SANS l'extension
    );

// Création du canal sur l'appareil
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(
      {required String title,
      required String body,
      required bool isMuted}) async {
    debugPrint("[showNotification] $title $body $isMuted");
    final userService = UserService();
    userService.init();
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'plop_channel_id',
      'Plop Notifications',
      priority: Priority.high,
      showWhen: false,
      color: Colors.transparent,
      icon: "icon",
      sound: (userService.isGlobalMute == false && !isMuted)
          ? const RawResourceAndroidNotificationSound('plop')
          : null,
    );

    // 2. Détails spécifiques à iOS et macOS (ils partagent la même classe)
    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true, // Afficher une alerte
      presentBadge: true, // Mettre à jour le badge de l'icône
      presentSound: true, // Jouer un son
      // subtitle: "plop",   // Affiche un sous-titre sous le titre principal
      sound: userService.isGlobalMute == false && !isMuted
          ? 'plop.aiff'
          : null, // Pour un son personnalisé
    );

    // 3. Détails spécifiques à Linux
    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails(
      defaultActionName: 'Ouvrir', // Nom de l'action par défaut
      // On peut aussi ajouter des actions personnalisées
    );

    // 4. Construire l'objet NotificationDetails avec toutes les plateformes
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
      // On réutilise la même configuration que pour iOS
      linux: linuxPlatformChannelSpecifics,
    );

    if (!isMuted) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 200);
      }
    }

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      // payload: 'item x',
    );
  }

  /// Gère un message entrant depuis le WebSocket, met à jour le contact
  /// et sauvegarde les changements en base de données.
  ///
  /// [update] est une Map contenant les données du message,
  /// par exemple : {'userId': 'some_id', 'payload': 'Hello!', 'timestamp': '2025-06-24T13:15:00Z'}
  // Future<void> handleIncomingMessage(Map<String, dynamic> update) async {
  //   // 1. Extraire les informations pertinentes du message reçu
  //   final String? userId = update['userId'];
  //   final String? messageText = update['payload'];
  //
  //   // Si les informations essentielles manquent, on ne fait rien.
  //   if (userId == null || messageText == null) {
  //     debugPrint("Erreur: Données de message incomplètes.");
  //     return;
  //   }
  //
  //   // 2. Récupérer le contact correspondant depuis la base de données
  //   final Contact? contact = _dbService.getContact(
  //       userId); // ou la méthode que vous utilisez pour trouver un contact
  //
  //   if (contact!.isMuted == false) {
  //     bool? hasVibrator = await Vibration.hasVibrator();
  //     if (hasVibrator ?? false) {
  //       Vibration.vibrate(duration: 200);
  //     }
  //   }
  //   // 3. Si le contact existe, le mettre à jour
  //   contact.lastMessage = messageText;
  //   contact.lastMessageTimestamp =
  //       DateTime.now(); // Utiliser l'heure de réception
  //
  //   // Optionnel : si le serveur envoie un timestamp, vous pouvez le parser et l'utiliser
  //   // if (update.containsKey('timestamp')) {
  //   //   contact.lastMessageTimestamp = DateTime.parse(update['timestamp']);
  //   // }
  //
  //   // 4. Sauvegarder les modifications du contact dans la base de données
  //   await contact.save(); // En supposant que votre modèle a une méthode save()
  //
  //   debugPrint("Message reçu pour l'utilisateur : $userId");
  //   debugPrint("Contact ${contact.userId} mis à jour avec le nouveau message.");
  // }

  void handlePlop(
      {String? fromUserId,
      String? messageText,
      bool? isDefaultMessage,
      bool? isPending,
      DateTime? sentDate,
      bool? fromExternalNotification}) async {
    if (fromUserId == null) {
      debugPrint("[handlePlop] fromUserId is null");
      return;
    }
    final db = DatabaseService();
    final contact = db.getContact(fromUserId);

    if (contact == null || (contact.isBlocked ?? false)) return;

    // CORRECTION : La logique utilise maintenant la variable `isDefaultMessage`
    final bool hasOverride = contact.defaultMessageOverride != null &&
        contact.defaultMessageOverride!.isNotEmpty;
    final String finalMessage;
    if ((hasOverride && isDefaultMessage!)) {
      finalMessage = contact.defaultMessageOverride!;
    } else {
      finalMessage = messageText!;
    }

    contact.lastMessage = finalMessage;

    contact.lastMessageTimestamp = sentDate?.toLocal() ?? DateTime.now();
    await db.updateContact(contact);

    final userService = UserService();
    await userService.init();
    bool isMuted = (contact.isMuted ?? false) == true;
    if (!fromExternalNotification! && (!isPending!)) {
      if (!isMuted && !userService.isGlobalMute) {
        debugPrint("[handlePlop] sound on");
        if (contact.customSoundPath != null &&
            contact.customSoundPath!.isNotEmpty) {
          await _audioPlayer.play(DeviceFileSource(contact.customSoundPath!));
        } else {
          await _audioPlayer.play(AssetSource('sounds/plop.mp3'));
        }
        debugPrint("[handlePlop] sound on then mute");
        isMuted = true;
      } else {
        debugPrint("[handlePlop] sound off");
      }
      NotificationService().showNotification(
          title: contact.alias, body: finalMessage, isMuted: isMuted);
    }

    _messageUpdateController.add({'userId': fromUserId});
  }
}

/// Obtient le token FCM actuel et l'envoie au serveur backend.
Future<void> sendFcmTokenToServer() async {
  // Récupérer une instance de vos services. Adaptez selon votre architecture.
  final userService = UserService();
  await userService.init();
  if (!userService.hasUser()) {
    debugPrint("Envoi du token annulé : aucun utilisateur n'est connecté.");
    return;
  }

  // 1. Obtenir le token FCM de l'appareil
  String? token = await FirebaseMessaging.instance.getToken();

  if (token == null) {
    debugPrint("Impossible d'obtenir le token FCM.");
    return;
  }

  debugPrint("Token FCM obtenu : $token");

  // 2. Préparer la requête HTTP POST
  final url = Uri.parse('${AppConfig.baseUrl}/users/update-token');
  final headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    // Si votre route était protégée, vous ajouteriez l'en-tête d'authentification ici.
  };
  final body = jsonEncode({
    'userId': userService.userId,
    'token': token,
  });

  // 3. Envoyer la requête
  try {
    debugPrint("Envoi du token au serveur : $body");
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint("Token FCM envoyé au serveur avec succès.");
    } else {
      debugPrint(
          "Échec de l'envoi du token au serveur. Statut : ${response.statusCode}, Corps : ${response.body}");
    }
  } catch (e) {
    debugPrint("Erreur réseau lors de l'envoi du token FCM : $e");
  }
}

Future<void> initializeWebSocket() async {
// Initialisation des services
  final webSocketService = WebSocketService();
  final databaseService = DatabaseService();
  final notificationService = NotificationService();

  // Lancer l'écouteur UNE SEULE FOIS pour toute l'application
  webSocketService.messageUpdates.listen((data) {
    debugPrint("Message reçu pour l'utilisateur : ${data['userId']}");

    final fromUserId = data['senderId'] ?? data['from'];
    if (fromUserId == null) {
      debugPrint("[handlePlop] fromUserId is null");
      return;
    }

    final messageText = data['payload'] as String;
    // On récupère le flag pour savoir si c'est un message par défaut
    final bool isDefaultMessage = (data['isDefault'] == 'true');
    final bool isPending = (data['IsPending'] == 'true');

    notificationService.handlePlop(fromUserId:fromUserId,messageText:messageText,isDefaultMessage: isDefaultMessage,isPending:isPending, sentDate:data['sendDate'],fromExternalNotification:false);
  });
}

Future<void> initializeNotificationPlugin() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialisation pour Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Votre icône d'app

  // Initialisation pour iOS/macOS
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  // Initialisation pour Linux
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open');

  // Regrouper les initialisations
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      // Action quand l'utilisateur clique sur la notification (toutes plateformes)
      if (notificationResponse.payload != null) {
        debugPrint('NOTIFICATION PAYLOAD: ${notificationResponse.payload}');
        if (notificationResponse.payload != null &&
            notificationResponse.payload!.isNotEmpty) {
          handleNotificationPayload(notificationResponse.payload!);
        }
      }
    },
  );

  // --- DEMANDER LES PERMISSIONS (CRUCIAL) ---
  // Pour iOS, macOS et maintenant Android 13+
  final bool? result;
  if (Platform.isAndroid) {
    result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } else if (Platform.isIOS) {
    result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isMacOS) {
    result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
  await sendToken();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Message received while app is in foreground!');
    debugPrint('Message data: ${message.data}');
    handleNotificationTap(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
        'User tapped on the notification to open the app from background.');
    debugPrint('Message data: ${message.data}');
    handleNotificationTap(message);
  });
}

Future<void> sendToken() async {
  // --- GESTION DU TOKEN FCM ---
  debugPrint("Configuration de la gestion du token FCM...");

  // Tente d'envoyer le token au serveur au cas où l'utilisateur serait déjà connecté.
  // La fonction `sendFcmTokenToServer` vérifiera elle-même si un utilisateur est connecté.
  await sendFcmTokenToServer();

  // Met en place l'écouteur pour les futurs rafraîchissements du token.
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint("Nouveau token FCM détecté. Envoi au serveur...");
    // Notre fonction se charge de récupérer le nouveau token et de l'envoyer.
    sendFcmTokenToServer();
  });
}

Future<void> checkNotificationFromTerminatedState() async {
  debugPrint("checkNotificationFromTerminatedState");
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
        "Application lancée depuis l'état 'terminated' par une notification.");
// Il n'y a pas besoin de délai, on peut appeler la fonction directement.
// La navigation se fera après que le premier écran soit construit.
    handleNotificationTap(initialMessage);
  }
}
