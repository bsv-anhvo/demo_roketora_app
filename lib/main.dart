import 'package:demo_roketota_app/screens/home_screen.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DemoRoketoraApp(),
    ),
  );
}

class DemoRoketoraApp extends StatelessWidget {
  const DemoRoketoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.labelApp,
      debugShowCheckedModeBanner: false,
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
