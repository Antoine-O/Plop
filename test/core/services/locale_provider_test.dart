import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/core/services/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleProvider', () {
    late LocaleProvider localeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeProvider = LocaleProvider();
    });

    test('initial locale is null', () {
      expect(localeProvider.locale, isNull);
    });

    test('setLocale updates locale and notifies listeners', () async {
      final locale = Locale('fr');
      var notified = false;
      localeProvider.addListener(() {
        notified = true;
      });

      localeProvider.setLocale(locale);

      expect(localeProvider.locale, locale);
      expect(notified, isTrue);
    });

    test('setLocale with null removes locale and notifies listeners', () async {
      localeProvider.setLocale(Locale('fr'));
      var notified = false;
      localeProvider.addListener(() {
        notified = true;
      });

      localeProvider.setLocale(null);

      expect(localeProvider.locale, isNull);
      expect(notified, isTrue);
    });

    test('loads locale from shared preferences on initialization', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'es'});
      // The LocaleProvider's constructor calls _loadLocale, which is async.
      // We need to allow that future to complete.
      final newLocaleProvider = LocaleProvider();
      await Future.delayed(Duration.zero);
      expect(newLocaleProvider.locale, Locale('es'));
    });
  });
}
