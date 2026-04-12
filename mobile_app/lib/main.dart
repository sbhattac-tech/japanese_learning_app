import 'package:flutter/material.dart';

import 'screens/landing_screen.dart';
import 'screens/language_selection_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const CognitaApp());
}

class CognitaApp extends StatelessWidget {
  const CognitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0E7C66);
    final auth = AuthService();

    return MaterialApp(
      title: 'Cognita',
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
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
      home: FutureBuilder<String?>(
        future: auth.getCurrentUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final username = snapshot.data;
          if (username == null || username.isEmpty) {
            return const LandingScreen();
          }
          return LanguageSelectionScreen(username: username);
        },
      ),
    );
  }
}
