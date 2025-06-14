
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
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

void main() {
  // On lance directement le widget de chargement
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const AppLoader(),
    ),
  );
}

// Ce widget gère l'initialisation des services.
class AppLoader extends StatefulWidget {
  const AppLoader({Key? key}) : super(key: key);

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

    await dotenv.load(fileName: ".env");
    // Initialisation des packages
    await Hive.initFlutter();
    await initializeDateFormatting('fr_FR', null); // Initialisation de la localisation

    // Enregistrement des adaptateurs Hive
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(MessageModelAdapter());

    // Initialisation des services
    await DatabaseService().init();
    await NotificationService().init();
    final userService = UserService();
    await userService.init();

    // Retourne le service utilisateur pour le passer à l'application
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
  const MyApp({Key? key, required this.userService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
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
    );
  }
}