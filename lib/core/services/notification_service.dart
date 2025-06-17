import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'plop_channel_id',
      'Plop Notifications',
      priority: Priority.high,
      showWhen: false
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
