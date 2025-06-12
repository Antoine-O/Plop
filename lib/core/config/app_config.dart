// lib/core/config/app_config.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plop_app/core/services/locale_provider.dart';
import 'package:provider/provider.dart';

class AppConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'http://localhost:8080';
  }

  static String get websocketUrl {
    return dotenv.env['WEBSOCKET_URL'] ?? 'ws://localhost:8080';
  }
  static String getDefaultPlopMessage(BuildContext? context) {
    // Récupère la langue du système (ex: "fr_FR" -> "fr")
    String languageCode;

    if (context != null) {
      final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
      languageCode = locale?.languageCode ?? Platform.localeName.split('_').first;
    } else {
      languageCode = Platform.localeName.split('_').first;
    }

    switch (languageCode) {
      case 'fr':
        return dotenv.env['DEFAULT_PLOP_FR'] ?? 'Plop !';
      case 'es':
        return dotenv.env['DEFAULT_PLOP_ES'] ?? '¡Plop!';
      case 'en':
      default:
        return dotenv.env['DEFAULT_PLOP_EN'] ?? 'Plop!';
    }
  }
}
