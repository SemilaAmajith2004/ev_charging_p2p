import 'package:flutter/material.dart';

import '../core/theme/app_color.dart';
import 'auth/role_selection_screen.dart';
import 'bookings/bookings_screen.dart';
import 'host/add_station_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  final UserRole initialRole;

  const MainLayout({super.key, this.initialRole = UserRole.driver});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late UserRole _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = _currentRole == UserRole.driver;

    final List<Widget> screens = isDriver
        ? [
            const MapScreen(),
            const BookingScreen(
              stationTitle: 'Solar Point Charging Hub',
              rate: 'Rs. 28.00 / kWh',
            ),
            const ProfileScreen(),
          ]
        : [
            const AddStationScreen(),
            const BookingScreen(
              stationTitle: 'Solar Point Charging Hub',
              rate: 'Rs. 28.00 / kWh',
            ),
            const ProfileScreen(),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.textSecondary,
        items: isDriver
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_border),
                  activeIcon: Icon(Icons.bookmark),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_location_alt_outlined),
                  activeIcon: Icon(Icons.add_location_alt),
                  label: 'Host Station',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Requests',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
