import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:monthly_count/screens/opening_screen.dart';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // A deep purple as the primary color
    secondary:
        Colors.greenAccent[700], // A vibrant green for interactive elements
    brightness: Brightness.light,
    surface: Colors.deepPurple[50], // Light purple surface color
  ),
  textTheme: GoogleFonts.latoTextTheme(TextTheme(
    headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple[900] // Deep purple for headlines
        ),
    labelLarge: TextStyle(
        letterSpacing: 1.2,
        color: Colors.deepPurple[300]), // Stylish letter spacing for labels
  )),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple[500], // Deep purple button backgrounds
      foregroundColor: Colors.white.withOpacity(0.9), // Text color on buttons
      shadowColor: Colors.black.withOpacity(0.3), // Subtle shadow for buttons
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.deepPurple[500], // Primary color for FAB
    foregroundColor: Colors.white.withOpacity(0.9), // Text color on FAB
    elevation: 5, // Elevation for the FAB
    shape: CircleBorder(), // Makes the FAB round
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.deepPurple[900]!), // Border color
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: Colors.greenAccent[700]!), // Focus border color
    ),
    hintStyle: TextStyle(
        color: Colors.deepPurple[900]!.withOpacity(0.5)), // Hint text color
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
