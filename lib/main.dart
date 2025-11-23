// import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/services/sync_service.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'package:plop/firebase_options.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/models/contact_model.dart';
import 'core/models/message_model.dart';
import 'core/services/database_service.dart';
import 'core/services/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/user_service.dart';
import 'features/contacts/contact_list_screen.dart';
import 'features/setup/setup_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// 1. Initialiser le plugin de notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializationHive() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(ContactAdapter().typeId)) {
    Hive.registerAdapter(ContactAdapter());
  }
  if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId)) {
    Hive.registerAdapter(MessageModelAdapter());
  }
  if (!Hive.isAdapterRegistered(MessageStatusAdapter().typeId)) {
    Hive.registerAdapter(MessageStatusAdapter());
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializationHive();

  debugPrint("[Background Service] Démarré et initialisé.");

  final dbService = DatabaseService();
  final userService = UserService();
  final localNotifications = FlutterLocalNotificationsPlugin();
  final notificationService =
      NotificationService(dbService, localNotifications);

  final WebSocketService webSocketService =
      WebSocketService(notificationService);

// Maintenant, les données sont disponibles dans cette instance de userService
  if (userService.hasUser()) {
    debugPrint(
        "[Background Service] Utilisateur trouvé (${userService.userId}). Connexion WebSocket...");

    // On appelle la méthode connect du WebSocketService
    // La méthode ensureConnected est mieux car elle contient la logique de vérification
    webSocketService.connect();
  } else {
    debugPrint(
        "[Background Service] Aucun utilisateur trouvé, pas de connexion WebSocket.");
  }
}

Future<Object> connectToApi() async {
  // Récupère l'URL compilée
  final String apiUrl = "${AppConfig.baseUrl}/ping";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
    return response;
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
    return e;
  }
}

Future<Object> connectToName() async {
  // Récupère l'URL compilée
  final String apiUrl = "https://www.google.com";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
    return response;
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
    return e;
  }
}

Future<Object> connectToIp() async {
  // Récupère l'URL compilée
  final String apiUrl = "https://8.8.8.8";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
    return response;
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
    return e;
  }
}

Future<void> main() async {
  // On lance directement le widget de chargement
  // AVOID SSL ERROR - to debug connection issues
  // HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed (expected on Linux/Windows if not configured): $e");
  }

  final dbService = DatabaseService();
  final localNotifications = FlutterLocalNotificationsPlugin();
  final notificationService =
      NotificationService(dbService, localNotifications);
  await notificationService.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: AppLoader(
        notificationService: notificationService,
      ),
    ),
  );
}

// Ce widget gère l'initialisation des services.
class AppLoader extends StatefulWidget {
  final NotificationService notificationService;
  const AppLoader({super.key, required this.notificationService});

  @override
  AppLoaderState createState() => AppLoaderState();
}

class AppLoaderState extends State<AppLoader> {
  late Future<UserService> _initializationFuture;

  @override
  void initState() {
    super.initState();
    debugPrint(
        "[AppLoader] initState: Démarrage de l'initialisation des services.");
    _initializationFuture = _initializeServices();
  }

  Future<UserService> _initializeServices() async {
    debugPrint("[AppLoader] _initializeServices: Début de l'initialisation.");
    // Garantit que les bindings Flutter sont prêts
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("[AppLoader] _initializeServices: Flutter bindings assurés.");

    // Initialisation des packages
    await initializationHive();
    debugPrint("[AppLoader] _initializeServices: Hive initialisé.");
    await initializeDateFormatting(
        'fr_FR', null); // Initialisation de la localisation
    debugPrint(
        "[AppLoader] _initializeServices: Formatage des dates initialisé pour fr_FR.");

    // Enregistrement des adaptateurs Hive
    // Hive.registerAdapter(ContactAdapter());
    // Hive.registerAdapter(MessageModelAdapter());
    // Hive.registerAdapter(MessageStatusAdapter());

    // Initialisation des services
    await DatabaseService().init();
    debugPrint("[AppLoader] _initializeServices: DatabaseService initialisé.");
    final userService = UserService();
    await userService.init();
    debugPrint(
        "[AppLoader] _initializeServices: UserService initialisé. User has data: ${userService.hasUser()}");
    await connectToIp();
    debugPrint(
        "[AppLoader] _initializeServices: Tentative de connexion à l'IP terminée.");
    await connectToName();
    debugPrint(
        "[AppLoader] _initializeServices: Tentative de connexion au nom de domaine terminée.");
    await connectToApi();
    debugPrint(
        "[AppLoader] _initializeServices: Tentative de connexion à l'API terminée.");
    // Retourne le service utilisateur pour le passer à l'application
    if (userService.hasUser()) {
      debugPrint(
          "[AppLoader] _initializeServices: Utilisateur trouvé. Vérification des notifications et envoi du token FCM.");
      await widget.notificationService.checkNotificationFromTerminatedState();
      debugPrint(
          "[AppLoader] _initializeServices: Vérification des notifications depuis l'état terminé, terminée.");
      // TODO: Get the actual token
      await widget.notificationService.sendFcmTokenToServer('');
      debugPrint(
          "[AppLoader] _initializeServices: Envoi du token FCM au serveur terminé.");
    } else {
      debugPrint(
          "[AppLoader] _initializeServices: Aucun utilisateur trouvé. Aucune action spécifique pour l'utilisateur existant.");
    }
    debugPrint(
        "[AppLoader] _initializeServices: Initialisation des services terminée.");
    return userService;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[AppLoader] build: Construction de l'interface utilisateur.");
    return FutureBuilder<UserService>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        debugPrint(
            "[AppLoader] FutureBuilder: État de la connexion: ${snapshot.connectionState}");
        // CORRECTION : On vérifie d'abord s'il y a une erreur pour l'afficher.
        if (snapshot.hasError) {
          debugPrint(
              "[AppLoader] FutureBuilder: Erreur rencontrée: ${snapshot.error}");
          debugPrintStack(
              stackTrace: snapshot.stackTrace,
              label: "[AppLoader] FutureBuilder StackTrace");
          return MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)!.criticalStartupError(
                        snapshot.error.toString(), // Ensure error is a String
                        snapshot.stackTrace.toString() // Ensure stackTrace is a String
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          debugPrint(
              "[AppLoader] FutureBuilder: Connexion terminée. Snapshot has data: ${snapshot.hasData}");
          // Si on arrive ici, snapshot.hasData est forcément vrai, car on a déjà géré le cas d'erreur.
          final userService = snapshot.data!;
          final notificationService = widget.notificationService;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<UserService>.value(value: userService),
              Provider<NotificationService>.value(value: notificationService),
              Provider<DatabaseService>(create: (_) => DatabaseService()),
              Provider<WebSocketService>(
                create: (_) {
                  debugPrint(
                      "[MyApp] MultiProvider: Création de WebSocketService.");
                  return WebSocketService(notificationService);
                },
                dispose: (_, service) {
                  debugPrint(
                      "[MyApp] MultiProvider: Suppression de WebSocketService.");
                  service.dispose();
                },
              ),
              ProxyProvider<WebSocketService, SyncService>(
                update: (_, webSocketService, __) => SyncService(webSocketService),
              ),
            ],
            child: const MyApp(),
          );
        }

        // Affiche un écran de chargement pendant l'initialisation
        debugPrint(
            "[AppLoader] FutureBuilder: Affichage de l'indicateur de chargement.");
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

// Le widget principal de l'application, maintenant lancé après l'initialisation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Les services sont maintenant fournis par un MultiProvider qui englobe MyApp.
    final userService = Provider.of<UserService>(context);
    final notificationService = Provider.of<NotificationService>(context);

    debugPrint(
        "[MyApp] build: Construction de l'interface utilisateur principale. L'utilisateur a des données: ${userService.hasUser()}");
    
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        debugPrint(
            "[MyApp] Consumer<LocaleProvider>: Construction de MaterialApp avec locale: ${localeProvider.locale}.");
        return MaterialApp(
          title: AppLocalizations.of(context)?.appName ?? "Plop",
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: userService.hasUser()
              ? const ContactListScreen()
              : SetupScreen(notificationService: notificationService),
        );
      },
    );
  }
}
