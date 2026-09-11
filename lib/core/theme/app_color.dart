import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds & Surfaces
  static const Color background = Color.fromARGB(255, 0, 0, 0); // Dark Obsidian
  static const Color surface = Color.fromARGB(255, 0, 0, 0); // Dark Slate Card
  static const Color surfaceLight = Color(0xFF334155);
  static const Color cardBackground = Color(0xFF161922);

  // Accent Neon Colors (EV Aesthetic)
  static const Color neonGreen = Color(0xFF00F5D4); // Fast Charging / Active
  static const Color neonBlue = Color.fromARGB(
    255,
    5,
    5,
    5,
  ); // Normal AC Charging
  static const Color solarAmber = Color(0xFFF59E0B); // Host / Solar Mode
  static const Color alertRed = Color(0xFFF43F5E); // Busy / Occupied

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color.fromARGB(255, 0, 0, 0);
}
