import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_color.dart';
import 'features/main/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.surface,
      systemNavigationBarColor: AppColors.surface,
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
