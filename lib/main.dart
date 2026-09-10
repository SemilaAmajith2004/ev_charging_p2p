import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const EVChargingApp());
}

class EVChargingApp extends StateLessWidget {
  const EVChargingApp ({super.key});

  @override
  Widget build (BuildContext context) {
    return MaterialApp(
      title : 'EV P2P Charging',
      debugShowCheckModeBanner : false,
      theme : const Scaffold (
        body : Center (
          child : Text(
            'EV P2P Charging Network'
            style : TextStyle (
              fontsize : 22,
              fontWeight : FontWeight.bold,
              color : AppColors.neonGreen,
            ),
          ),
        ),
      ),
    );
  }
}