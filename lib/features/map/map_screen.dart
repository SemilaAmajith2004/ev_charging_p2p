import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/data/dummy_stations.dart';
import '../../core/models/ev_station_model.dart';
import '../../core/theme/app_color.dart';
import '../payment/payment_screen.dart';

/// Main discovery screen for the P2P EV charging app.
/// It contains the map, search/filter logic, and the bottom station list.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _locationPromptShown = false;
  StreamSubscription<Position>? _locationSubscription;

  String _searchQuery = '';
  final Set<ConnectorType> _selectedConnectors = {};
  bool _showFastChargingOnly = false;
  bool _showAvailableOnly = false;
  double _maxPrice = 150;
  String? _selectedStationId;

  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Returns all stations filtered by text, connector, availability, speed, and price.
  List<EVStationModel> get _filteredStations {
    final query = _searchQuery.trim().toLowerCase();

    return dummyStations.where((station) {
      final matchesQuery =
          query.isEmpty ||
          station.title.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query);

      final matchesConnector =
          _selectedConnectors.isEmpty ||
          station.connectors.any(_selectedConnectors.contains);

      final matchesAvailability = !_showAvailableOnly || station.isAvailable;

      final matchesFastCharging =
          !_showFastChargingOnly ||
          station.speed.toLowerCase().contains('fast') ||
          station.speed.toLowerCase().contains('dc');

      final matchesPrice = station.pricePerKwh <= _maxPrice;

      return matchesQuery &&
          matchesConnector &&
          matchesAvailability &&
          matchesFastCharging &&
          matchesPrice;
    }).toList();
  }

  /// Returns the nearest stations ordered by distance from the user's current location.
  List<EVStationModel> get _stationCarousel {
    final center = _currentLocation ?? _defaultCenter;

    final stations = [..._filteredStations];
    stations.sort((a, b) {
      final da = _calculateDistance(center, a.location);
      final db = _calculateDistance(center, b.location);
      return da.compareTo(db);
    });

    return stations.take(5).toList();
  }

  double _calculateDistance(LatLng from, LatLng to) {
    return const Distance().as(LengthUnit.Kilometer, from, to);
  }

  /// Request and validate live user location.
  Future<void> _fetchUserLocation() async {
    final fallbackLocation = _defaultCenter;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentLocation = fallbackLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(fallbackLocation, 11.0);
        _showLocationSettingsDialog();
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentLocation = fallbackLocation;
            _isLoadingLocation = false;
          });
          _mapController.move(fallbackLocation, 11.0);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentLocation = fallbackLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(fallbackLocation, 11.0);
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
                  'To center the map on your live location, allow location access in app settings.',
                  style: TextStyle(color: Colors.white70),
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
                    child: const Text('Open settings'),
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
          _currentLocation = fallbackLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(fallbackLocation, 11.0);
      }
    }
  }

  void _updateCurrentLocation(Position position) {
    if (!mounted) return;

    final latLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLocation = latLng;
      _isLoadingLocation = false;
    });

    _mapController.move(latLng, 13.0);
  }

  void _showLocationSettingsDialog() {
    if (!mounted || _locationPromptShown) return;

    _locationPromptShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Enable your location',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Location services are off. You can still browse nearby chargers, but live positioning is disabled.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.background,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final openedSettings = await Geolocator.openLocationSettings();
              if (!openedSettings && mounted) {
                await Geolocator.openAppSettings();
              }
              if (mounted) {
                await _fetchUserLocation();
              }
            },
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
  }

  void _moveToUserLocation() {
    if (_currentLocation == null) {
      _locationPromptShown = false;
      _fetchUserLocation();
      return;
    }

    _mapController.move(_currentLocation!, 13.0);
  }

  /// Opens the filter sheet to tweak connector, availability, and pricing filters.
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filters = [
              _FilterChipOption(
                label: 'Fast Charging',
                selected: _showFastChargingOnly,
                onSelected: (selected) {
                  setState(() => _showFastChargingOnly = selected);
                  setModalState(() => _showFastChargingOnly = selected);
                },
              ),
              _FilterChipOption(
                label: 'Available Now',
                selected: _showAvailableOnly,
                onSelected: (selected) {
                  setState(() => _showAvailableOnly = selected);
                  setModalState(() => _showAvailableOnly = selected);
                },
              ),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedConnectors.clear();
                            _showFastChargingOnly = false;
                            _showAvailableOnly = false;
                            _maxPrice = 150;
                          });
                          setModalState(() {
                            _selectedConnectors.clear();
                            _showFastChargingOnly = false;
                            _showAvailableOnly = false;
                            _maxPrice = 150;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.neonGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connector type',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ConnectorType.values.map((connector) {
                      final selected = _selectedConnectors.contains(connector);
                      return ChoiceChip(
                        label: Text(connector.name.toUpperCase()),
                        selected: selected,
                        selectedColor: AppColors.neonGreen,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.background
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedConnectors.add(connector);
                            } else {
                              _selectedConnectors.remove(connector);
                            }
                          });
                          setModalState(() {
                            if (value) {
                              _selectedConnectors.add(connector);
                            } else {
                              _selectedConnectors.remove(connector);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.label),
                          selected: filter.selected,
                          selectedColor: AppColors.neonGreen,
                          backgroundColor: AppColors.background,
                          onSelected: filter.onSelected,
                          labelStyle: TextStyle(
                            color: filter.selected
                                ? AppColors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Max price / kWh',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.neonGreen,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppColors.neonGreen,
                      overlayColor: AppColors.neonGreen.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _maxPrice,
                      min: 40,
                      max: 200,
                      divisions: 16,
                      label: 'LKR ${_maxPrice.toStringAsFixed(0)}',
                      onChanged: (value) {
                        setState(() => _maxPrice = value);
                        setModalState(() => _maxPrice = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
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
    final isSelected = _selectedStationId == station.id;
    final isAvailable = station.isAvailable;
    final markerColor = isAvailable
        ? AppColors.neonGreen
        : AppColors.solarAmber;

    return Marker(
      point: station.location,
      width: 120,
      height: 82,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedStationId = station.id);
          _openStationDetailsSheet(station);
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonGreen : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: markerColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                'LKR ${station.pricePerKwh.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: markerColor, size: 22),
          ],
        ),
      ),
    );
  }

  Marker _buildUserMarker() {
    return Marker(
      point: _currentLocation ?? _defaultCenter,
      width: 32,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.my_location_rounded, color: Colors.blue, size: 16),
        ),
      ),
    );
  }

  void _openStationDetailsSheet(EVStationModel station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: station.isAvailable
                        ? AppColors.neonGreen.withValues(alpha: 0.12)
                        : AppColors.solarAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    station.isAvailable ? 'Available' : 'In use',
                    style: TextStyle(
                      color: station.isAvailable
                          ? AppColors.neonGreen
                          : AppColors.solarAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.neonGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.address,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailPill(label: 'Power', value: station.speed),
                _detailPill(
                  label: 'Price',
                  value: 'LKR ${station.pricePerKwh.toStringAsFixed(0)}/kWh',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.solarAmber),
                const SizedBox(width: 6),
                Text(
                  '${station.rating.toStringAsFixed(1)} rating',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _filteredStations.map(_buildStationMarker).toList();
    if (_currentLocation != null) {
      markers.add(_buildUserMarker());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? _defaultCenter,
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.ev_charging_p2p',
                  tileProvider: NetworkTileProvider(),
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '⚡ Nearby EV Stations',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.18),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search stations, roads, or areas',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.neonGreen,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.neonGreen,
                          ),
                          onPressed: _openFilterSheet,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterPill(
                          label: 'Fast Charging',
                          selected: _showFastChargingOnly,
                          onTap: () => setState(
                            () =>
                                _showFastChargingOnly = !_showFastChargingOnly,
                          ),
                        ),
                        _FilterPill(
                          label: 'Type 2',
                          selected: _selectedConnectors.contains(
                            ConnectorType.type2,
                          ),
                          onTap: () => setState(() {
                            if (_selectedConnectors.contains(
                              ConnectorType.type2,
                            )) {
                              _selectedConnectors.remove(ConnectorType.type2);
                            } else {
                              _selectedConnectors.add(ConnectorType.type2);
                            }
                          }),
                        ),
                        _FilterPill(
                          label: 'CCS2',
                          selected: _selectedConnectors.contains(
                            ConnectorType.ccs2,
                          ),
                          onTap: () => setState(() {
                            if (_selectedConnectors.contains(
                              ConnectorType.ccs2,
                            )) {
                              _selectedConnectors.remove(ConnectorType.ccs2);
                            } else {
                              _selectedConnectors.add(ConnectorType.ccs2);
                            }
                          }),
                        ),
                        _FilterPill(
                          label: 'Available Now',
                          selected: _showAvailableOnly,
                          onTap: () => setState(
                            () => _showAvailableOnly = !_showAvailableOnly,
                          ),
                        ),
                        _FilterPill(
                          label: 'Up to LKR $_maxPrice',
                          selected: _maxPrice < 200,
                          onTap: _openFilterSheet,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 18,
              bottom: 220,
              child: FloatingActionButton(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.neonGreen,
                elevation: 4,
                onPressed: _moveToUserLocation,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.neonGreen,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.18,
                maxChildSize: 0.42,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 5,
                          margin: const EdgeInsets.only(top: 12, bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            itemCount: _stationCarousel.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final station = _stationCarousel[index];
                              return SizedBox(
                                width: 280,
                                child: _StationCard(
                                  station: station,
                                  selected: _selectedStationId == station.id,
                                  onTap: () {
                                    setState(
                                      () => _selectedStationId = station.id,
                                    );
                                    _openStationDetailsSheet(station);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.neonGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.neonGreen : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipOption {
  const _FilterChipOption({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.selected,
    required this.onTap,
  });

  final EVStationModel station;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonGreen.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.neonGreen : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1593941707882-a5bac6861d75?auto=format&fit=crop&w=800&q=80',
                    width: 76,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.solarAmber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            station.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: station.isAvailable
                                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                                  : AppColors.solarAmber.withValues(
                                      alpha: 0.18,
                                    ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              station.isAvailable ? 'Open' : 'Busy',
                              style: TextStyle(
                                color: station.isAvailable
                                    ? AppColors.neonGreen
                                    : AppColors.solarAmber,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.electric_bolt_rounded,
                  color: AppColors.neonGreen,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  station.speed,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'LKR ${station.pricePerKwh.toStringAsFixed(0)}/kWh',
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _detailPill({required String label, required String value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
