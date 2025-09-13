
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plop/constants/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme has correct properties', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.fontFamily, 'Inter');
      expect(theme.colorScheme.primary, const Color(0xFF6A1B9A));
      expect(theme.colorScheme.secondary, const Color(0xFF00ACC1));
      expect(theme.colorScheme.brightness, Brightness.light);

      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.backgroundColor, Colors.white);
      expect(theme.appBarTheme.foregroundColor, Colors.black);

      final elevatedButtonTheme = theme.elevatedButtonTheme.style;
      expect(elevatedButtonTheme?.backgroundColor?.resolve({}), const Color(0xFF6A1B9A));
      expect(elevatedButtonTheme?.foregroundColor?.resolve({}), Colors.white);
      expect(elevatedButtonTheme?.padding?.resolve({}), const EdgeInsets.symmetric(horizontal: 24, vertical: 16));
      expect(elevatedButtonTheme?.shape?.resolve({}), RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
    });

    test('darkTheme has correct properties', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.fontFamily, 'Inter');
      expect(theme.colorScheme.primary, const Color(0xFF6A1B9A));
      expect(theme.colorScheme.secondary, const Color(0xFF00ACC1));
      expect(theme.colorScheme.brightness, Brightness.dark);

      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.centerTitle, isTrue);

      final elevatedButtonTheme = theme.elevatedButtonTheme.style;
      expect(elevatedButtonTheme?.backgroundColor?.resolve({}), const Color(0xFF6A1B9A));
      expect(elevatedButtonTheme?.foregroundColor?.resolve({}), Colors.white);
      expect(elevatedButtonTheme?.padding?.resolve({}), const EdgeInsets.symmetric(horizontal: 24, vertical: 16));
      expect(elevatedButtonTheme?.shape?.resolve({}), RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
    });
  });
}
