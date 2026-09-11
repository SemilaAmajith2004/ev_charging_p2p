import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart'; // app_color.dart ලෙස භාවිත කර ඇත

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(
          alpha: 0.9,
        ), // Transparent Translucent Effect
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 1.0),
          width: 1.5,
        ), 
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.neonGreen),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search EV Chargers in Sri Lanka...',
                hintStyle: TextStyle(
                  color: Color.fromARGB(255, 146, 137, 137),
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.neonBlue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
