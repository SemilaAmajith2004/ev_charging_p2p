import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_color.dart';
import 'core/theme/app_theme.dart';
import 'features/main/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure system UI styling (Status Bar & Navigation Bar) matches dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Keeps status bar background clean
      statusBarIconBrightness: Brightness.light, // For Android (light icons on dark bg)
      statusBarBrightness: Brightness.dark, // For iOS (light text/icons)
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