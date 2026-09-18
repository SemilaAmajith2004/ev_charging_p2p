import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_color.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_screen.dart';
import 'features/auth/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once; if config is missing or fails, report it without
  // leaving the app in a half-initialized state.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
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
      // Firebase Auth Stream එක මගින් User Login status එක අනුව Screen එක තීරණය කරයි
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Connection state එක waiting නම් Loading indicator එකක් පෙන්වයි
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // User log වී සිටී නම් MainScreen එකටද නැතහොත් LoginScreen එකටද මාරු වේ
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}
