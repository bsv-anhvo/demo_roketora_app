import 'package:demo_roketota_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported app locales: English and Japanese.
const List<Locale> supportedAppLocales = <Locale>[
  Locale('en'),
  Locale('ja'),
];

const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

// final localeProvider = StateProvider<Locale?>((Ref ref) => null);
final localeProvider = StateProvider<Locale?>((Ref ref) => const Locale('ja')); // Setting default locale to Japanese to review app

Locale appLocaleResolutionCallback(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
  if (deviceLocale?.languageCode == 'ja') {
    return const Locale('ja');
  }
  return const Locale('en');
}