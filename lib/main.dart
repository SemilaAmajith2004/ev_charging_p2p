import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_color.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_screen.dart';

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'Firebase initialization',
        context: ErrorDescription(
          'Firebase initialization failed at app startup',
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once; if config is missing or fails, report it without
  // leaving the app in a half-initialized state.
  await _initializeFirebase();

  // Notification Service initialization
  try {
    await NotificationService().initNotification();
  } catch (e) {
    debugPrint("Notification Service Initialization Error: $e");
  }

  // Ensure system UI styling (Status Bar & Navigation Bar) matches dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const EVChargingApp());
}

class EVChargingApp extends StatelessWidget {
  const EVChargingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV P2P Charging Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
