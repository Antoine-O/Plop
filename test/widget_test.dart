// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // On doit initialiser les dépendances que l'app attend, comme SharedPreferences.
    SharedPreferences.setMockInitialValues({});

    // On crée une instance du service requis.
    final userService = UserService();
    // On s'assure qu'il est initialisé avant de l'utiliser.
    await userService.init();

    // On construit notre application en passant le paramètre requis.
    // Notez que le `const` a été retiré car userService n'est pas une constante.
    await tester.pumpWidget(MyApp(userService: userService));

    // On peut ajouter un test simple, par exemple vérifier qu'un texte initial est présent.
    // Ce test est très basique et devra être adapté à l'évolution de votre UI.
    expect(find.text('Plop'), findsOneWidget);
  });
}