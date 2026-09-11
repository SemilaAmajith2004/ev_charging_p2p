import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_color.dart';
import '../bookings/bookings_screen.dart';
import 'widgets/search_filter_bar.dart';

// Station දත්ත කළමනාකරණයට Model එකක්
class EVStation {
  final String title;
  final String speed;
  final String price;
  final LatLng location;

  const EVStation({
    required this.title,
    required this.speed,
    required this.price,
    required this.location,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // EV Stations ලැයිස්තුව
  final List<EVStation> _stations = const [
    EVStation(
      title: 'Colombo Solar Station',
      speed: '22 kW Fast AC',
      price: 'Rs. 85 / kWh',
      location: LatLng(6.9271, 79.8612),
    ),
    EVStation(
      title: 'Kandy Fast Charger',
      speed: '22 kW Fast AC',
      price: 'Rs. 85 / kWh',
      location: LatLng(7.2906, 80.6337),
    ),
  ];

  // Station Details Bottom Sheet Modal එක පෙන්වන Function එක
  void _showStationDetails(BuildContext context, EVStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    station.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.bolt, color: AppColors.neonGreen, size: 28),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Speed: ${station.speed}',
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Rate: ${station.price}',
                style: const TextStyle(
                  color: AppColors.solarAmber,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Bottom Sheet එක Close කරයි
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          stationTitle: station.title,
                          rate: station.price,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Book Charging Slot',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom Marker Widget එක සාදන Function එක
  Marker _buildStationMarker(EVStation station) {
    return Marker(
      point: station.location,
      width: 60,
      height: 70,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _showStationDetails(context, station),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonGreen,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.ev_station,
                color: AppColors.neonGreen,
                size: 22,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.surface,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng defaultCenter = const LatLng(6.9271, 79.8612);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: OpenStreetMap Layer
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.yourapp', // මෙතැන ඔබගේ app එකේ package name එක යොදන්න
),
                MarkerLayer(
                  markers: _stations.map(_buildStationMarker).toList(),
                ),
              ],
            ),

            // Layer 2: Top Floating Search & Filter Bar
            const Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: SearchFilterBar(),
            ),

            // Layer 3: North Compass Button
            Positioned(
              right: 16,
              top: 100,
              child: FloatingActionButton(
                mini: true,
                backgroundColor:
                    const Color.fromARGB(255, 254, 255, 255).withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 255, 0, 0),
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  _mapController.rotate(0.0);
                  _mapController.move(
                    _mapController.camera.center,
                    15.0,
                  );
                },
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color.fromARGB(255, 255, 0, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}