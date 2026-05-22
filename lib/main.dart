import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_ai/pages/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final String geminiApiKey = 'AIzaSyAGuDhopQOkJlvkGGLe4dN7YjcXDi_pImI';
  Gemini.init(apiKey: geminiApiKey);

  FlutterNativeSplash.remove();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 23, 23, 30),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: Color.fromARGB(255, 23, 23, 30),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 23, 23, 30),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
