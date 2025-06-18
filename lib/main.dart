import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plop/core/config/app_config.dart';
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

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  final WebSocketService _webSocketService = WebSocketService();
  final userService = UserService();

  void connectWebSocket() {
    try {
      if (userService.userId != null && userService.username != null) {
        _webSocketService.connect(userService.userId!, userService.username!);
      }
    } catch (e) {
      debugPrint('Erreur de connexion WebSocket: $e');
    }
  }

  connectWebSocket();
}

void connectToApi() async {
  // Récupère l'URL compilée
  final String apiUrl = "${AppConfig.baseUrl}/ping";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
  }
}

void connectToName() async {
  // Récupère l'URL compilée
  final String apiUrl = "https://www.google.com";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
  }
}

void connectToIp() async {
  // Récupère l'URL compilée
  final String apiUrl = "https://8.8.8.8";
  debugPrint(
      'Tentative de connexion à : $apiUrl'); // Vérifiez que l'URL est parfaite

  try {
    final response = await http.get(Uri.parse(apiUrl));
    debugPrint('Réponse reçue: ${response.statusCode}');
  } catch (e) {
    // C'EST LA PARTIE LA PLUS IMPORTANTE !
    debugPrint('ERREUR DE CONNEXION DÉTAILLÉE: $e');
  }
}

Future<void> main() async {
  // On lance directement le widget de chargement
  // AVOID SSL ERROR - to debug connection issues
  // HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeNotificationPlugin();
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const AppLoader(),
    ),
  );
}

// Ce widget gère l'initialisation des services.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  _AppLoaderState createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late Future<UserService> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeServices();
  }

  Future<UserService> _initializeServices() async {
    // Garantit que les bindings Flutter sont prêts
    WidgetsFlutterBinding.ensureInitialized();

    // Initialisation des packages
    await Hive.initFlutter();
    await initializeDateFormatting(
        'fr_FR', null); // Initialisation de la localisation

    // Enregistrement des adaptateurs Hive
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(MessageModelAdapter());

    // Initialisation des services
    await DatabaseService().init();
    await NotificationService().init();
    final userService = UserService();
    await userService.init();
    connectToIp();
    connectToName();
    connectToApi();
    // Retourne le service utilisateur pour le passer à l'application
    if (userService.hasUser()) {
      await sendFcmTokenToServer();
    }
    return userService;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserService>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // CORRECTION : On vérifie d'abord s'il y a une erreur pour l'afficher.
        if (snapshot.hasError) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erreur critique lors du démarrage :\n\n${snapshot.error}\n\n${snapshot.stackTrace}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          // Si on arrive ici, snapshot.hasData est forcément vrai, car on a déjà géré le cas d'erreur.
          return MyApp(userService: snapshot.data!);
        }

        // Affiche un écran de chargement pendant l'initialisation
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
  final UserService userService;

  const MyApp({super.key, required this.userService});

  @override
  Widget build(BuildContext context) {
    connectToIp();
    connectToName();
    connectToApi();
    return MultiProvider(
        providers: [
          // On fournit l'instance de UserService qui a été initialisée dans AppLoader
          ChangeNotifierProvider<UserService>.value(value: userService),

          // On fournit aussi le LocaleProvider comme vous le faisiez déjà
          ChangeNotifierProvider<LocaleProvider>(
              create: (_) => LocaleProvider()),
        ],
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            return MaterialApp(
              title: 'Plop',
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
              home: userService.hasUser() ? ContactListScreen() : SetupScreen(),
            );
          },
        )
    );
  }
}

void handleNotificationPayload(String payload) {
  try {
    // final Map<String, dynamic> data = jsonDecode(payload);

    // if (data['action'] == 'open_chat') {
    //   final String chatId = data['chatId'];

    // Utilisation de la GlobalKey pour naviguer sans BuildContext !
    navigatorKey.currentState?.pushNamed('/');
    // }
    // Ajoutez d'autres 'if' pour d'autres actions
  } catch (e) {
    debugPrint('Erreur lors du traitement du payload de notification : $e');
  }
}

/// Gère la navigation quand une notification est cliquée.
void handleNotificationTap(RemoteMessage message) {
  debugPrint("Gestion du clic sur la notification ! Payload de données : ${message.data}");


    debugPrint('App launched from terminated state via notification!');
    // Handle navigation here, similar to onMessageOpenedApp
    debugPrint(
        'User tapped on the notification to open the app from background.');
    WebSocketService webSocketService = WebSocketService();
    webSocketService.handlePlop(message.data);

  // Vous pouvez ajouter d'autres 'if' pour d'autres types de notifications
}

