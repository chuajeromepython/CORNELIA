import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_ai/pages/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final bool crashlyticsSupported =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (crashlyticsSupported) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
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
