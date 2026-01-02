import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrisaKidsApp());
}

class BrisaKidsApp extends StatelessWidget {
  const BrisaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrisaKids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8FB3FF)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FF),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
