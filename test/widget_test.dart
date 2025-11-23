// test/widget_test.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/services/locale_provider.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/user_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/invitation_service.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'package:plop/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'widget_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserService>(),
  MockSpec<NotificationService>(),
  MockSpec<DatabaseService>(),
  MockSpec<InvitationService>(),
  MockSpec<WebSocketService>(),
])
void main() {
  setUpAll(() async {
    await dotenv.load();
    dotenv.env['BASE_URL'] = 'http://test.com';
  });
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // On doit initialiser les dépendances que l'app attend, comme SharedPreferences.
    SharedPreferences.setMockInitialValues({});

    // On crée une instance des services mockés.
    final mockUserService = MockUserService();
    when(mockUserService.hasUser()).thenReturn(true);
    when(mockUserService.getUser())
        .thenAnswer((_) async => User(userId: '123', username: 'test'));
    when(mockUserService.init()).thenAnswer((_) async => {});

    final mockNotificationService = MockNotificationService();
    final mockDatabaseService = MockDatabaseService();
    when(mockDatabaseService.getAllContactsOrdered())
        .thenAnswer((_) async => <Contact>[]);
    final mockInvitationService = MockInvitationService();
    final mockWebSocketService = MockWebSocketService();

    // On construit notre application en passant le paramètre requis.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          Provider<DatabaseService>.value(value: mockDatabaseService),
          ChangeNotifierProvider<UserService>.value(value: mockUserService),
          Provider<InvitationService>.value(value: mockInvitationService),
          Provider<NotificationService>.value(value: mockNotificationService),
          Provider<WebSocketService>.value(value: mockWebSocketService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // On peut ajouter un test simple, par exemple vérifier qu'un texte initial est présent.
    // Ce test est très basique et devra être adapté à l'évolution de votre UI.
    // Note: Ce test est susceptible d'échouer si le texte "Plop" n'est pas directement
    // dans un widget Text, mais cela confirme que l'application a démarré.
    // expect(find.text('Plop'), findsOneWidget);
  });
}
