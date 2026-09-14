import 'package:latlong2/latlong.dart';

enum ConnectorType { type2, ccs2, chademo, wallSocket }

class EVStationModel {
  final String id;
  final String hostId;
  final String title;
  final String address;
  final String speed; // e.g., '22 kW Fast AC'
  final double pricePerKwh;
  final LatLng location;
  final List<ConnectorType> connectors;
  final bool isAvailable;
  final double rating;

  const EVStationModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.address,
    required this.speed,
    required this.pricePerKwh,
    required this.location,
    required this.connectors,
    this.isAvailable = true,
    this.rating = 5.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'title': title,
      'address': address,
      'speed': speed,
      'pricePerKwh': pricePerKwh,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'connectors': connectors.map((e) => e.name).toList(),
      'isAvailable': isAvailable,
      'rating': rating,
    };
  }

  factory EVStationModel.fromJson(Map<String, dynamic> json) {
    return EVStationModel(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      speed: json['speed'] as String,
      pricePerKwh: (json['pricePerKwh'] as num).toDouble(),
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      connectors: (json['connectors'] as List<dynamic>)
          .map((e) => ConnectorType.values.byName(e as String))
          .toList(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }
}