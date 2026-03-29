import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const JapaneseLearningApp());
}

class JapaneseLearningApp extends StatelessWidget {
  const JapaneseLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0E7C66);

    return MaterialApp(
      title: 'Japanese Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F6F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F6F1),
          foregroundColor: Color(0xFF11221D),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
