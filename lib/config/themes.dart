import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static const Color lightBg = Color(0xFFE7ECEF);
  static const Color lightPrimary = Color(0xFF274C77);
  static const Color lightSecondary = Color(0xFF6096BA);
  static const Color lightSurface = Color(0xFFA3CEF1);
  static const Color lightMuted = Color(0xFF8B8C89);
  /// Main text / on-surface for light themes (a touch darker than default seed grey).
  static const Color lightOnSurface = Color(0xFF0A0A0A);
  static const Color darkBg = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF1B263B);
  static const Color darkPrimary = Color(0xFF415A77);
  static const Color darkSecondary = Color(0xFF6096ba);
  static const Color darkOn = Color(0xFFE0E1DD);

  static const Color designBg = Color(0xFF22223B);
  static const Color designSurface = Color(0xFF4A4E69);
  static const Color designPrimary = Color(0xFF9A8C98);
  static const Color designSecondary = Color(0xFFca8683);
  static const Color designOn = Color(0xFFedf6f9);
  static const Color olivePrimary = Color(0xFF606C38);
  static const Color oliveDark = Color(0xFF283618);
  static const Color oliveBg = Color(0xFFFEFAE0);
  static const Color oliveCanvas = Color(0xFFEBE6D4);
  static const Color oliveOnSurfaceVariant = Color(0xFF5C6148);
  static const Color oliveSecondary = Color(0xFFDDA15E);
  static const Color oliveAccent = Color(0xFFBC6C25);
  static const Color summerPrimary = Color(0xFF5AA9E6);
  static const Color summerSecondary = Color(0xFF7FC8F8);
  static const Color summerAccent = Color(0xFFF7A8B8);
  static const Color summerWarm = Color(0xFFFFF1E6);
  static const Color summerBg = Color(0xFFF9F9F9);
  static const Color summerOnSurfaceVariant = Color(0xFF6D7B8A);

  /// Peachy: sage canvas, cream cards, mauve chrome, rose/blush accents.
  static const Color peachySage = Color(0xFFD8E2DC);
  static const Color peachyCream = Color(0xFFFFE5D9);
  static const Color peachyBlush = Color(0xFFFFCAD4);
  static const Color peachyRose = Color(0xFFF4ACB7);
  static const Color peachyMauve = Color(0xFF9D8189);
  static const Color peachyOnSurfaceVariant = Color(0xFF7A6A72);

  /// Rose: white page, blush cards, mauve chrome, coral & teal accents.
  static const Color roseWhite = Color(0xFFFFFFFF);
  static const Color roseBlush = Color(0xFFFFCAD4);
  static const Color roseTeal = Color(0xFFB0D0D3);
  static const Color roseMauve = Color(0xFFC08497);
  static const Color roseCoral = Color(0xFFF7AF9D);
  static const Color roseOnSurfaceVariant = Color(0xFF8B6F7A);

  static ThemeData get defaultTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: const Color(0xFFFF6B6B),
        error: const Color(0xFFad2e24),
        surface: lightSurface,
        surfaceContainerHighest: lightBg,
        onPrimary: Colors.white,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightMuted,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightSecondary, width: 1),
        ),
        color: lightBg,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.72),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: darkSecondary,
        error: const Color(0xFFc44536),
        surface: darkSurface,
        // Match cards / inputs — not a light M3 default (was washing out sliders & chips on dark cards).
        surfaceContainerHighest: darkSurface,
        onSurfaceVariant: const Color(0xFFA3ABB3),
        onPrimary: darkOn,
        onSurface: darkOn,
      ),
      scaffoldBackgroundColor: darkBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: darkSecondary,
        displayColor: darkSecondary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkPrimary, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSecondary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkSurface,
        foregroundColor: darkOn,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkOn,
        unselectedItemColor: darkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get designTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: designPrimary,
        brightness: Brightness.dark,
        primary: designPrimary,
        secondary: designSecondary,
        error: const Color(0xFFb66166),
        surface: designSurface,
          // Match cards / inputs — same as dark fix (seed “highest” was too light on this palette).
          surfaceContainerHighest: designSurface,
        onSurfaceVariant: const Color(0xFFA3ABB3),
        onPrimary: designOn,
        onSurface: designOn
      ),
      scaffoldBackgroundColor: designBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFa69aa5),
        displayColor: const Color(0xFFa69aa5),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: designSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: designPrimary, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: designSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: designPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: designPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: designSecondary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: designSurface,
        foregroundColor: designOn,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: designSurface,
        selectedItemColor: designOn,
        unselectedItemColor: designPrimary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get oliveTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: olivePrimary,
        brightness: Brightness.light,
        primary: olivePrimary,
        secondary: oliveSecondary,
        tertiary: oliveAccent,
        error: const Color(0xFFad2e24),
        // Like default: surface = page, surfaceContainerHighest = cards / menus / chips.
        surface: oliveCanvas,
        surfaceContainerHighest: oliveBg,
        onPrimary: Colors.white,
        onSurface: oliveDark,
        onSurfaceVariant: oliveOnSurfaceVariant,
      ),
      scaffoldBackgroundColor: oliveCanvas,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: oliveDark,
        displayColor: oliveDark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: oliveBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: oliveSecondary, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F2D9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oliveSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oliveSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: olivePrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: olivePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: olivePrimary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: olivePrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFFDCC8A9),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get summerTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: summerPrimary,
        brightness: Brightness.light,
        primary: summerPrimary,
        secondary: summerSecondary,
        tertiary: summerAccent,
        error: const Color(0xFFad2e24),
        surface: summerBg,
        // Same as card fill so chips / menus match default + summer cards.
        surfaceContainerHighest: summerWarm,
        onPrimary: Colors.white,
        onSurface: lightOnSurface,
        onSurfaceVariant: summerOnSurfaceVariant,
      ),
      scaffoldBackgroundColor: summerBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: summerWarm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: summerWarm, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: summerBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: summerWarm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: summerWarm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: summerPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: summerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: summerPrimary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: summerPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFFDCEFFE),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get peachyTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: peachyMauve,
        brightness: Brightness.light,
        primary: peachyMauve,
        secondary: peachyRose,
        tertiary: peachyBlush,
        error: const Color(0xFFad2e24),
        surface: peachySage,
        surfaceContainerHighest: peachyCream,
        onPrimary: Colors.white,
        onSurface: lightOnSurface,
        onSurfaceVariant: peachyOnSurfaceVariant,
      ),
      scaffoldBackgroundColor: peachySage,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: peachyCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: peachyRose, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: peachyBlush,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: peachyRose),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: peachyRose),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: peachyMauve, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: peachyMauve,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: peachyMauve,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: peachyMauve,
        selectedItemColor: Colors.white,
        unselectedItemColor: peachyBlush,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get roseTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: roseMauve,
        brightness: Brightness.light,
        primary: roseMauve,
        secondary: roseCoral,
        tertiary: roseTeal,
        error: const Color(0xFFad2e24),
        surface: roseWhite,
        surfaceContainerHighest: roseBlush,
        onPrimary: Colors.white,
        onSurface: lightOnSurface,
        onSurfaceVariant: roseOnSurfaceVariant,
      ),
      scaffoldBackgroundColor: roseWhite,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: lightOnSurface,
        displayColor: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: roseBlush,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: roseCoral, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: roseTeal,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: roseCoral),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: roseCoral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: roseMauve, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: roseMauve,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: roseMauve,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: roseMauve,
        selectedItemColor: Colors.white,
        unselectedItemColor: roseTeal,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
