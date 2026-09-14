import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_color.dart';
import '../bookings/bookings_screen.dart';
import 'widgets/search_filter_bar.dart';

class EVStation {
  final String id;
  final String title;
  final String speed;
  final String price;
  final LatLng location;

  const EVStation({
    required this.id,
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

  // Booked Time Slot details (Station ID -> Selected DateTime)
  final Map<String, DateTime> _bookedSlots = {};

  final List<EVStation> _stations = const [
    EVStation(
      id: 'colombo_01',
      title: 'Colombo Solar Station',
      speed: '22 kW Fast AC',
      price: 'Rs. 85 / kWh',
      location: LatLng(6.9271, 79.8612),
    ),
    EVStation(
      id: 'kandy_01',
      title: 'Kandy Fast Charger',
      speed: '22 kW Fast AC',
      price: 'Rs. 85 / kWh',
      location: LatLng(7.2906, 80.6337),
    ),
  ];

  // Navigate to Booking Screen and handle returned DateTime
  void _openBookingScreen(EVStation station) async {
    final selectedTime = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingScreen(stationTitle: station.title, rate: station.price),
      ),
    );

    if (!mounted) return;

    if (selectedTime != null) {
      setState(() {
        _bookedSlots[station.id] = selectedTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Slot Booked for ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}!',
          ),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    }
  }

  // Real-time Station Bottom Sheet using StatefulBuilder & Timer
  void _showStationStatusBottomSheet(EVStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Timer? timer;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Periodic timer to recalculate arrival status every second
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (sheetContext.mounted) {
                setSheetState(() {});
              }
            });

            DateTime? bookedTime = _bookedSlots[station.id];
            bool isBooked = bookedTime != null;

            bool isTimeArrived = false;
            if (isBooked) {
              final now = DateTime.now();
              isTimeArrived =
                  now.isAfter(bookedTime) || now.isAtSameMomentAs(bookedTime);
            }

            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                timer?.cancel();
              },
              child: Padding(
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
                        const Icon(
                          Icons.bolt,
                          color: AppColors.neonGreen,
                          size: 28,
                        ),
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
                    const SizedBox(height: 15),

                    if (isBooked) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTimeArrived
                              ? AppColors.neonGreen.withValues(alpha: 0.15)
                              : AppColors.solarAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTimeArrived
                                ? AppColors.neonGreen
                                : AppColors.solarAmber,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTimeArrived
                                  ? Icons.access_time_filled
                                  : Icons.timer,
                              color: isTimeArrived
                                  ? AppColors.neonGreen
                                  : AppColors.solarAmber,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isTimeArrived
                                    ? 'Your time slot has arrived! Tap Arrived to start charging.'
                                    : 'Booked Slot: ${bookedTime.hour.toString().padLeft(2, '0')}:${bookedTime.minute.toString().padLeft(2, '0')} (Waiting...)',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBooked
                              ? (isTimeArrived
                                    ? AppColors.neonGreen
                                    : Colors.grey)
                              : AppColors.neonGreen,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (!isBooked) {
                            timer?.cancel();
                            Navigator.pop(sheetContext);
                            _openBookingScreen(station);
                          } else if (isTimeArrived) {
                            timer?.cancel();
                            setState(() {
                              _bookedSlots.remove(station.id);
                            });

                            Navigator.pop(sheetContext);

                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.neonGreen,
                                      size: 28,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Success!',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'Arrived successfully at ${station.title}. Your charging session is now active!',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: AppColors.neonGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please wait until your scheduled time slot arrives.',
                                ),
                                backgroundColor: AppColors.solarAmber,
                              ),
                            );
                          }
                        },
                        child: Text(
                          !isBooked
                              ? 'Go to Booking Window'
                              : (isTimeArrived
                                    ? 'Arrived'
                                    : 'Waiting for Time Slot'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Marker _buildStationMarker(EVStation station) {
    bool isBooked = _bookedSlots.containsKey(station.id);

    return Marker(
      point: station.location,
      width: 60,
      height: 70,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          if (_bookedSlots.containsKey(station.id)) {
            _showStationStatusBottomSheet(station);
          } else {
            _openBookingScreen(station);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isBooked ? AppColors.solarAmber : AppColors.neonGreen,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isBooked ? AppColors.solarAmber : AppColors.neonGreen)
                            .withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.ev_station,
                color: isBooked ? AppColors.solarAmber : AppColors.neonGreen,
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
    const LatLng defaultCenter = LatLng(6.9271, 79.8612);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ev_charging_p2p',
                  // Some environments block OSM requests; this keyless fallback is the
                  // simplest option without requiring a third-party API key.
                ),
                MarkerLayer(
                  markers: _stations.map(_buildStationMarker).toList(),
                ),
              ],
            ),
            const Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: SearchFilterBar(),
            ),
            Positioned(
              right: 16,
              top: 100,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color.fromARGB(
                  255,
                  254,
                  255,
                  255,
                ).withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 255, 0, 0),
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  _mapController.rotate(0.0);
                  _mapController.move(_mapController.camera.center, 15.0);
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
