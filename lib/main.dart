import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:monthly_count/screens/opening_screen.dart';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0075FF), // Vibrant Revolut-style blue
    brightness: Brightness.light,
    primary: const Color(0xFF0075FF), // Vibrant blue - Revolut style
    secondary: const Color(0xFF00D4AA), // Vibrant teal/green
    tertiary: const Color(0xFFFF6B6B), // Vibrant coral/red
    error: const Color(0xFFFF3B30), // Bright red
    surface: const Color(0xFFF5F7FA), // Light gray-blue
    surfaceContainerHighest: const Color(0xFFE8ECF1), // Lighter gray
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF1A1A1A), // Dark text
    onSurfaceVariant: const Color(0xFF6C7A89), // Medium gray text
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1A1A1A),
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      color: const Color(0xFF1A1A1A),
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF1A1A1A),
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF6C7A89),
        ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: const Color(0xFFE5E7EB),
        width: 1,
      ),
    ),
    color: Colors.white,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0075FF),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF0075FF),
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF0075FF), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    hintStyle: GoogleFonts.inter(
      color: const Color(0xFF9CA3AF),
      fontSize: 16,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF1A1A1A),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1A1A1A),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF0075FF),
    unselectedItemColor: const Color(0xFF9CA3AF),
    selectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const ProviderScope(child: MontlyCount()));
  });
}


class MontlyCount extends StatelessWidget {
  const MontlyCount({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YesISpend',
      theme: theme,
      // home: const MainViewScreen(),
      home: const OpeningScreen(),
    );
  }
}
