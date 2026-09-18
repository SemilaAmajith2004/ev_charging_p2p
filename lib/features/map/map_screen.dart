import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/data/dummy_stations.dart';
import '../../core/models/ev_station_model.dart';
import '../../core/theme/app_color.dart';
import '../bookings/bookings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _locationPromptShown = false;
  StreamSubscription<Position>? _locationSubscription;

  final Map<String, DateTime> _bookedSlots = {};

  // Active Filters State
  ConnectorType? _selectedConnector;
  String _searchQuery = '';

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

  // Filtered stations logic based on search text and selected connector
  List<EVStationModel> get _filteredStations {
    return dummyStations.where((station) {
      final matchesQuery =
          station.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          station.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesConnector =
          _selectedConnector == null ||
          station.connectors.contains(_selectedConnector);

      return matchesQuery && matchesConnector;
    }).toList();
  }

  void _showLocationSettingsDialog() {
    if (!mounted || _locationPromptShown) return;

    _locationPromptShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Turn on location',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Please enable location services so your live position can appear on the map.',
            style: TextStyle(color: Color.fromARGB(255, 255, 253, 253)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.background,
              ),
              onPressed: () async {
                Navigator.pop(context);

                final openedLocationSettings =
                    await Geolocator.openLocationSettings();
                if (!openedLocationSettings && mounted) {
                  await Geolocator.openAppSettings();
                }

                if (mounted) {
                  await _fetchUserLocation();
                }
              },
              child: const Text('Turn on'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchUserLocation() async {
    const defaultLocation = LatLng(6.9271, 79.8612);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentLocation = defaultLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(defaultLocation, 11.0);
        _showLocationSettingsDialog();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentLocation = defaultLocation;
            _isLoadingLocation = false;
          });
          _mapController.move(defaultLocation, 11.0);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentLocation = defaultLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(defaultLocation, 11.0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text(
                  'Location permission required',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: const Text(
                  'Please allow location access in app settings to show your live map position.',
                  style: TextStyle(color: Color.fromARGB(255, 253, 252, 252)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
          }
        });
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _updateCurrentLocation(position);
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(6.9271, 79.8612);
          _isLoadingLocation = false;
        });
        _mapController.move(const LatLng(6.9271, 79.8612), 11.0);
      }
    }
  }

  void _updateCurrentLocation(Position position) {
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });

    // Automatically center map to user position once retrieved
    _mapController.move(_currentLocation!, 13.0);
  }

  void _moveToUserLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14.0);
    } else {
      _locationPromptShown = false;
      _fetchUserLocation();
    }
  }

  void _openStationDetailsBottomSheet(EVStationModel station) {
    final bool isBooked = _bookedSlots.containsKey(station.id);

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
                  Expanded(
                    child: Text(
                      station.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? AppColors.solarAmber.withValues(alpha: 0.2)
                          : AppColors.neonGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBooked ? 'Booked' : 'Available',
                      style: TextStyle(
                        color: isBooked
                            ? AppColors.solarAmber
                            : AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color.fromARGB(255, 255, 255, 255),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      station.address,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        station.rate,
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connectors',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        station.connectors
                            .map((e) => e.name.toUpperCase())
                            .join(', '),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(
                          stationTitle: station.title,
                          rate: station.rate,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Book Station',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Charging Stations',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() => _selectedConnector = null);
                          setState(() => _selectedConnector = null);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.solarAmber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Connector Type',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: ConnectorType.values.map((type) {
                      final isSelected = _selectedConnector == type;
                      return ChoiceChip(
                        label: Text(
                          type.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.neonGreen,
                        backgroundColor: AppColors.surface,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedConnector = selected ? type : null;
                          });
                          setState(() {
                            _selectedConnector = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Marker _buildStationMarker(EVStationModel station) {
    bool isBooked = _bookedSlots.containsKey(station.id);

    return Marker(
      point: station.location,
      width: 60,
      height: 70,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _openStationDetailsBottomSheet(station),
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

  Marker _buildUserLocationMarker() {
    return Marker(
      point: _currentLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> stationMarkers = _filteredStations
        .map(_buildStationMarker)
        .toList();

    if (_currentLocation != null) {
      stationMarkers.add(_buildUserLocationMarker());
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(6.9271, 79.8612), // Default Colombo
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.ev_charging_p2p',
                ),
                MarkerLayer(markers: stationMarkers),
              ],
            ),

            // Search Bar & Filter Button Overlay
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search EV stations...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.neonGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _selectedConnector != null
                          ? AppColors.neonGreen
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: _selectedConnector != null
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                      onPressed: _openFilterDialog,
                    ),
                  ),
                ],
              ),
            ),

            // My Location Floating Action Button
            Positioned(
              bottom: 20,
              right: 15,
              child: FloatingActionButton(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.neonGreen,
                onPressed: _moveToUserLocation,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neonGreen,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
