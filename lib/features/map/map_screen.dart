import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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

  // User current location tracking
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  StreamSubscription<Position>? _locationSubscription;

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

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // Location Permissions handle කිරීම සහ Current Location එක ලබාගැනීම
  Future<void> _fetchUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable device location services.'),
            backgroundColor: AppColors.solarAmber,
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _updateCurrentLocation(position);
      _startLiveLocationTracking();
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _updateCurrentLocation(Position position) {
    if (!mounted) return;

    final nextLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = nextLocation;
      _isLoadingLocation = false;
    });

    _mapController.move(nextLocation, 14.0);
  }

  void _startLiveLocationTracking() {
    _locationSubscription?.cancel();

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        _updateCurrentLocation(position);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  // Navigate to Booking Screen and handle returned DateTime
  Future<void> _openBookingScreen(EVStation station) async {
    final selectedTime = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          stationTitle: station.title,
          rate: station.price,
        ),
      ),
    );

    if (!mounted || selectedTime == null) return;

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

  // Real-time Station Bottom Sheet using StatefulBuilder & Timer
  void _showStationStatusBottomSheet(EVStation station) {
    Timer? timer;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
              isTimeArrived = now.isAfter(bookedTime) || now.isAtSameMomentAs(bookedTime);
            }

            return PopScope(
              canPop: true,
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
                                    onPressed: () => Navigator.pop(dialogContext),
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
    ).whenComplete(() {
      timer?.cancel();
    });
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
                    color: (isBooked ? AppColors.solarAmber : AppColors.neonGreen)
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

  // User Current Location Marker එක නිර්මාණය කිරීම
  Marker _buildUserLocationMarker() {
    return Marker(
      point: _currentLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const LatLng defaultCenter = LatLng(6.9271, 79.8612);

    // Dynamic Markers List (Stations + Current User Location)
    final List<Marker> allMarkers = _stations.map(_buildStationMarker).toList();
    if (_currentLocation != null) {
      allMarkers.add(_buildUserLocationMarker());
    }

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
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.ev_charging_p2p',
                ),
                MarkerLayer(markers: allMarkers),
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
                backgroundColor: const Color.fromARGB(255, 255, 254, 255)
                    .withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 255, 0, 0),
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  _mapController.rotate(0.0);
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  } else {
                    _mapController.move(_mapController.camera.center, 15.0);
                  }
                },
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color.fromARGB(255, 255, 0, 0),
                ),
              ),
            ),
            if (_isLoadingLocation)
              const Positioned(
                bottom: 20,
                left: 20,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Fetching location...'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}