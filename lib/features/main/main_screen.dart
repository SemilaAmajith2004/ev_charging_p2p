import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';
import '../map/map_screen.dart';
import '../bookings/bookings_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Bottom Navigation Bar එකේ Tabs 4ට අනුරූප Screens 4
  final List<Widget> _screens = [
    const MapScreen(),
    const BookingScreen(
      stationTitle: 'Solar Point Charging Hub',
      rate: 'Rs. 28.00 / kWh',
    ),
    const Center(
      child: Text(
        'Wallet Screen',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
    ),
    const ProfileScreen(), // Profile Screen එක direct ලෙස එකතු කර ඇත
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.85),
          border: const Border(
            top: BorderSide(color: AppColors.neonGreen, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonGreen.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.neonGreen,
          unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map, color: AppColors.neonGreen),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt, color: AppColors.neonGreen),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(
                Icons.account_balance_wallet,
                color: AppColors.neonGreen,
              ),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.neonGreen),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
