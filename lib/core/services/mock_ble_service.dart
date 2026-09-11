import 'dart:async';

enum BleConnectionState { disconnected, scanning, connecting, connected }

class MockBleService {
  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _batteryController = StreamController<double>.broadcast();

  Timer? _dataTimer;
  double _currentBatteryLevel = 0.45;
  BleConnectionState _currentState = BleConnectionState.disconnected;

  Stream<BleConnectionState> get connectionState => _stateController.stream;
  Stream<double> get batteryPercentageStream => _batteryController.stream;

  Future<bool> connectToBikeDevice(String deviceAddress) async {
    _updateState(BleConnectionState.scanning);
    await Future.delayed(const Duration(seconds: 1));

    _updateState(BleConnectionState.connecting);
    await Future.delayed(const Duration(seconds: 1));

    _updateState(BleConnectionState.connected);
    _startTransmittingBatteryData();
    return true;
  }

  void _startTransmittingBatteryData() {
    _dataTimer?.cancel();
    _batteryController.add(_currentBatteryLevel);

    _dataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentState != BleConnectionState.connected) return;

      if (_currentBatteryLevel < 1.0) {
        _currentBatteryLevel = (_currentBatteryLevel + 0.05).clamp(0.0, 1.0);
        _batteryController.add(_currentBatteryLevel);
      }
    });
  }

  void disconnect() {
    _dataTimer?.cancel();
    _updateState(BleConnectionState.disconnected);
  }

  void _updateState(BleConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    _dataTimer?.cancel();
    _stateController.close();
    _batteryController.close();
  }
}