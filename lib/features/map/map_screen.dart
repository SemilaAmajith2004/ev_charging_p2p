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
      final matchesQuery = station.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          station.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesConnector = _selectedConnector == null ||
          station.connectors.contains(_selectedConnector);

      return matchesQuery && matchesConnector;
    }).toList();
  }

  Future<void> _fetchUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
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
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _updateCurrentLocation(Position position) {
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });
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
                        child: const Text('Reset', style: TextStyle(color: AppColors.solarAmber)),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Connector Type',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
                            color: isSelected ? AppColors.background : AppColors.textPrimary,
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
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
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
        onTap: () {
          // Open station booking details
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
                  ),
                ],
              ),
              child: Icon(
                Icons.ev_station,
                color: isBooked ? AppColors.solarAmber : AppColors.neonGreen,
                size: 22,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.surface, size: 26),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> stationMarkers =
        _filteredStations.map(_buildStationMarker).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(6.9271, 79.8612),
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Search EV stations...',
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
          ],
        ),
      ),
    );
  }
}