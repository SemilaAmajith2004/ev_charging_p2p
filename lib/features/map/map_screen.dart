import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo Location: Colombo, Sri Lanka
    final LatLng colomboLocation = const LatLng(6.9271, 79.8612);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Nearby EV Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.neonGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: colomboLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ev_charging_p2p',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: colomboLocation,
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solar Home Charger - 22kW Fast AC'),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.ev_station,
                    color: AppColors.neonGreen,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}