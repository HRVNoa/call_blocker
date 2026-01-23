import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CallBlockerApp());
}

class CallBlockerApp extends StatelessWidget {
  const CallBlockerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti-Démarchage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
