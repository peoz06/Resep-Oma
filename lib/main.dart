import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DapurKitaApp());
}

class DapurKitaApp extends StatefulWidget {
  const DapurKitaApp({super.key});

  @override
  State<DapurKitaApp> createState() => _DapurKitaAppState();
}

class _DapurKitaAppState extends State<DapurKitaApp> {
  bool _darkMode = false;

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resep Oma — Komunitas Resep & Kuliner',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: MainNavigationScreen(
        darkMode: _darkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}
