import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manzil_app_v3/screens/splash_screen.dart';

import 'firebase_options.dart';

// var kLightColorScheme = ColorScheme.fromSeed(
//   seedColor: const Color.fromARGB(255, 52, 59, 113),
// );

// Yellow Color
// color: Color.fromARGB(255, 255, 170, 42)

// Carrot Color
// color: Color.fromARGB(255, 255, 107, 74)

// black variant
// Color.fromARGB(255, 45, 45, 45)

// Input field Text
// color: Color.fromRGBO(30, 60, 87, 1)

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 52, 59, 113),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 255, 170, 42),
    selectionColor: Color.fromARGB(100, 255, 255, 255),
    selectionHandleColor:
    Color.fromARGB(255, 255, 170, 42),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // HttpOverrides.global = MyHttpOverrides();
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Manzil', theme: theme, home: const SplashScreen());
    // home: const SplashScreen(),
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
