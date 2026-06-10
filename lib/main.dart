import 'package:demo_roketota_app/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DemoRoketotaApp());
}

class DemoRoketotaApp extends StatelessWidget {
  const DemoRoketotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Roketota App',
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
