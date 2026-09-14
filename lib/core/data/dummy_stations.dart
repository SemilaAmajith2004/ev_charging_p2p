import 'package:latlong2/latlong.dart';
import '../models/ev_station_model.dart';

final List<EVStationModel> dummyStations = [
  const EVStationModel(
    id: 'colombo_01',
    hostId: 'host_101',
    title: 'Colombo Solar Station',
    address: 'Galle Road, Colombo 03',
    speed: '22 kW Fast AC',
    pricePerKwh: 85.0,
    location: LatLng(6.9271, 79.8612),
    connectors: [ConnectorType.type2, ConnectorType.wallSocket],
    isAvailable: true,
    rating: 4.8,
  ),
  const EVStationModel(
    id: 'colombo_02',
    hostId: 'host_102',
    title: 'City Center Supercharger',
    address: 'Sir James Peiris Mawatha, Colombo 02',
    speed: '50 kW DC Fast',
    pricePerKwh: 110.0,
    location: LatLng(6.9186, 79.8558),
    connectors: [ConnectorType.ccs2, ConnectorType.chademo],
    isAvailable: true,
    rating: 4.9,
  ),
  const EVStationModel(
    id: 'kandy_01',
    hostId: 'host_103',
    title: 'Kandy Fast Charger',
    address: 'Peradeniya Road, Kandy',
    speed: '22 kW Fast AC',
    pricePerKwh: 85.0,
    location: LatLng(7.2906, 80.6337),
    connectors: [ConnectorType.type2],
    isAvailable: false,
    rating: 4.5,
  ),
];