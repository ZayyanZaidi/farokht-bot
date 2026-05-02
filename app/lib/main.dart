import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/app_nav_shell.dart';
import 'services/api_service.dart';


final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  
  runApp(const FarokhtBotApp());
}

class FarokhtBotApp extends StatelessWidget {
  const FarokhtBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Farokht Bot',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5CE1E6),
              primary: const Color(0xFFFF8C00),
              secondary: const Color(0xFF5CE1E6),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Cleaner light background
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5CE1E6),
              primary: const Color(0xFFFF8C00),
              secondary: const Color(0xFF5CE1E6),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
          ),
          home: const AppNavShell(),
        );
      },
    );
  }
}

