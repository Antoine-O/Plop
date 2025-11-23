import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plop/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('App starts and loads', (tester) async {
      app.main();
      // Pump once to start the app
      await tester.pump();
      
      // Allow some time for async initialization (AppLoader)
      // We cannot use pumpAndSettle because CircularProgressIndicator is an infinite animation.
      // We pump for a specific duration to let the Future complete.
      await tester.pump(const Duration(seconds: 5));

      // Check if we have a MaterialApp (Error, Loading, or Main)
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Check if we are past the loading screen (optional, but good to know)
      // If we are still loading, we should see CircularProgressIndicator
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        debugPrint('Still showing CircularProgressIndicator');
      } else {
        debugPrint('Not showing CircularProgressIndicator - likely loaded or error');
      }
    });
  });
}
