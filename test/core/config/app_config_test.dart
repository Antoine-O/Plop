import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() async {
      dotenv.testLoad(fileInput: '''
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
      expect(
        AppConfig.getDefaultPlopMessage(null, locale: const Locale('fr')),
        'Salut !',
      );
    });

    test('getDefaultPlopMessage returns correct value for Spanish', () {
      expect(
        AppConfig.getDefaultPlopMessage(null, locale: const Locale('es')),
        '¡Hola!',
      );
    });

    test('getDefaultPlopMessage returns correct value for English', () {
      expect(
        AppConfig.getDefaultPlopMessage(null, locale: const Locale('en')),
        'Hello!',
      );
    });

    test('getDefaultPlopMessage returns default value for unsupported language',
        () {
      expect(
        AppConfig.getDefaultPlopMessage(null, locale: const Locale('de')),
        'Hello!',
      );
    });

    test('getDefaultPlopMessage returns default value when context is null',
        () {
      expect(AppConfig.getDefaultPlopMessage(null), 'Hello!');
    });
  });
}
