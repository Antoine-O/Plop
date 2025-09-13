
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plop/core/config/app_config.dart';
import 'package.provider/provider.dart';
import 'package:plop/core/services/locale_provider.dart';

class MockBuildContext extends Mock implements BuildContext {}
class MockLocaleProvider extends Mock implements LocaleProvider {}

void main() {
  group('AppConfig', () {
    setUp(() async {
      dotenv.loadFromString(envString: '''
        BASE_URL=https://api.example.com
        WEBSOCKET_URL=wss://api.example.com/ws
        DEFAULT_PLOP_FR=Salut !
        DEFAULT_PLOP_ES=¡Hola!
        DEFAULT_PLOP_EN=Hello!
      ''');
    });

    test('baseUrl returns correct value from dotenv', () {
      expect(AppConfig.baseUrl, 'https://api.example.com');
    });

    test('websocketUrl returns correct value from dotenv', () {
      expect(AppConfig.websocketUrl, 'wss://api.example.com/ws');
    });

    test('getDefaultPlopMessage returns correct value for French', () {
      final mockContext = MockBuildContext();
      final mockLocaleProvider = MockLocaleProvider();
      when(mockLocaleProvider.locale).thenReturn(const Locale('fr'));

      final widget = ChangeNotifierProvider<LocaleProvider>.value(
        value: mockLocaleProvider,
        child: Builder(
          builder: (context) {
            expect(AppConfig.getDefaultPlopMessage(context), 'Salut !');
            return Container();
          },
        ),
      );

      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.render(widget, renderView: false);
    });

    test('getDefaultPlopMessage returns correct value for Spanish', () {
      final mockContext = MockBuildContext();
      final mockLocaleProvider = MockLocaleProvider();
      when(mockLocaleProvider.locale).thenReturn(const Locale('es'));

      final widget = ChangeNotifierProvider<LocaleProvider>.value(
        value: mockLocaleProvider,
        child: Builder(
          builder: (context) {
            expect(AppConfig.getDefaultPlopMessage(context), '¡Hola!');
            return Container();
          },
        ),
      );
      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.render(widget, renderView: false);
    });

    test('getDefaultPlopMessage returns correct value for English', () {
      final mockContext = MockBuildContext();
      final mockLocaleProvider = MockLocaleProvider();
      when(mockLocaleProvider.locale).thenReturn(const Locale('en'));

      final widget = ChangeNotifierProvider<LocaleProvider>.value(
        value: mockLocaleProvider,
        child: Builder(
          builder: (context) {
            expect(AppConfig.getDefaultPlopMessage(context), 'Hello!');
            return Container();
          },
        ),
      );

      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.render(widget, renderView: false);
    });

    test('getDefaultPlopMessage returns default value for unsupported language', () {
      final mockContext = MockBuildContext();
      final mockLocaleProvider = MockLocaleProvider();
      when(mockLocaleProvider.locale).thenReturn(const Locale('de'));

      final widget = ChangeNotifierProvider<LocaleProvider>.value(
        value: mockLocaleProvider,
        child: Builder(
          builder: (context) {
            expect(AppConfig.getDefaultPlopMessage(context), 'Hello!');
            return Container();
          },
        ),
      );

      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.render(widget, renderView: false);
    });

    test('getDefaultPlopMessage returns default value when context is null', () {
      expect(AppConfig.getDefaultPlopMessage(null), 'Hello!');
    });
  });
}
