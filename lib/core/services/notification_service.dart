import 'dart:io';
import 'dart:convert'; // Pour jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:plop/core/config/app_config.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
    const InitializationSettings initializationSettings = InitializationSettings(
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
      description: 'Canal pour les notifications Plop avec un son personnalisé.',
      importance: Importance.max,
      playSound: true, // Très important
      sound: RawResourceAndroidNotificationSound('plop'), // Nom du fichier SANS l'extension
    );

// Création du canal sur l'appareil
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);


  }
  final userService = UserService();
  Future<void> showNotification({required String title, required String body, required bool isMuted}) async {


    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'plop_channel_id',
      'Plop Notifications',
      priority: Priority.high,
      showWhen: false,
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
      sound: 'plop.aiff', // Pour un son personnalisé
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
      macOS: darwinPlatformChannelSpecifics, // On réutilise la même configuration que pour iOS
      linux: linuxPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}



/// Obtient le token FCM actuel et l'envoie au serveur backend.
Future<void> sendFcmTokenToServer() async {
  // Récupérer une instance de vos services. Adaptez selon votre architecture.
  final userService = UserService();
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
      debugPrint("Échec de l'envoi du token au serveur. Statut : ${response.statusCode}, Corps : ${response.body}");
    }
  } catch (e) {
    debugPrint("Erreur réseau lors de l'envoi du token FCM : $e");
  }
}



Future<void>  initializeNotificationPlugin() async {
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
        print('NOTIFICATION PAYLOAD: ${notificationResponse.payload}');
        // Naviguer vers un écran spécifique
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
