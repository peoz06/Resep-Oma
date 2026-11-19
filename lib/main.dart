import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/main_navigation_screen.dart';
import 'services/firebase_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Aplikasi tetap jalan bila Firebase belum dikonfigurasi (mode offline).
  await FirebaseService.init();
  await SupabaseService.init();
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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
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
