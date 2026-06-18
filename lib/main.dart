import 'package:demo_roketota_app/l10n/app_localizations.dart';
import 'package:demo_roketota_app/providers/locale_provider.dart';
import 'package:demo_roketota_app/screens/home_screen.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFmpegKitConfig.init();

  runApp(
    const ProviderScope(
      child: DemoRoketoraApp(),
    ),
  );
}

class DemoRoketoraApp extends ConsumerWidget {
  const DemoRoketoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp(
      title: Strings.labelApp,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: localizationsDelegates,
      localeResolutionCallback: appLocaleResolutionCallback,
      builder: (BuildContext context, Widget? child) {
        Strings.bind(AppLocalizations.of(context));
        return child ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          secondary: const Color(0xFFE53935),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
