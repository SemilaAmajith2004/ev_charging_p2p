  import 'package:flutter/material.dart';
  import 'core/theme/app_colors.dart';
  import 'core/theme/app_theme.dart';
  import 'features/map/map_screen.dart';

  void main() {
    runApp(const EVChargingApp());
  }

  class EVChargingApp extends StatelessWidget {
    const EVChargingApp({super.key});

    @override
    Widget build (BuildContext context) {
      return MaterialApp(
        title : 'EV P2P Charging',
        debugShowCheckModeBanner : false,
        home: const MapScreen(),
        theme : AppTheme.darkTheme (
          body : Center (
            child : Text(
              'EV P2P Charging Network'
              style : TextStyle (
                fontSize : 22,
                fontWeight : FontWeight.bold,
                color : AppColors.neonGreen,
              ),
            ),
          ),
        ),
      );
    }
  }