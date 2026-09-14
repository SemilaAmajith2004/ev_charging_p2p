import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';
import '../../core/services/mock_ble_service.dart';
import 'liquid_battery_widget.dart';
import 'sun_moon_arc_widget.dart';

class BookingScreen extends StatefulWidget {
  final String stationTitle;
  final String rate;

  const BookingScreen({
    super.key,
    required this.stationTitle,
    required this.rate,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final MockBleService _bleService = MockBleService();

  String selectedSlot = '10:00 AM - 11:00 AM';
  BleConnectionState _bleState = BleConnectionState.disconnected;
  double liveBikeBatteryPercentage = 0.45;
  bool _hasAlertedFullCharge = false;

  // Book වූ සියලුම Slots තබා ගන්නා List එක
  final List<String> bookedSlots = ['09:00 AM - 10:00 AM'];

  // Book කළ Slot වල Message History
  final List<Map<String, String>> _bookedMessages = [
    {
      'slot': '09:00 AM - 10:00 AM',
      'station': 'Colombo Fast Charge Station',
      'time': '08:45 AM',
    }
  ];

  StreamSubscription? _batterySub;
  StreamSubscription? _stateSub;

  final List<String> timeSlots = const [
    '08:00 AM - 09:00 AM',
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '02:00 PM - 03:00 PM',
  ];

  @override
  void initState() {
    super.initState();

    _stateSub = _bleService.connectionState.listen((state) {
      if (!mounted) return;
      setState(() => _bleState = state);

      if (state == BleConnectionState.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-Bike Connected Successfully! Receiving battery data...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    _batterySub = _bleService.batteryPercentageStream.listen((battery) {
      if (!mounted) return;
      setState(() => liveBikeBatteryPercentage = battery);

      // Bluetooth Connected නම් පමණක් 100% Alert එක Trigger වේ
      if (_bleState == BleConnectionState.connected &&
          battery >= 1.0 &&
          !_hasAlertedFullCharge) {
        _hasAlertedFullCharge = true;
        _triggerFullChargeAlert();
      }
    });
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _stateSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  void _connectToBike() {
    _bleService.connectToBikeDevice('00:1B:44:11:3A:B7');
  }

  void _triggerFullChargeAlert() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.battery_charging_full, color: AppColors.neonGreen, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Battery Fully Charged!',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔔 BEEP! BEEP! BEEP!\nYour E-Bike is now 100% charged. Please unplug to avoid overcharging.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.background,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK / Stop Alert'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog() {
    if (bookedSlots.contains(selectedSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This slot is already booked! Please select another.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String currentTimeFormatted = TimeOfDay.now().format(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Slot Booking',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Slot:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                selectedSlot,
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Estimated Rate',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                widget.rate,
                style: const TextStyle(
                  color: AppColors.solarAmber,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.background,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  bookedSlots.add(selectedSlot);
                  _bookedMessages.insert(0, {
                    'slot': selectedSlot,
                    'station': widget.stationTitle,
                    'time': currentTimeFormatted,
                  });

                  // Automatically switch selectedSlot to next available slot if possible
                  final availableSlots = timeSlots.where((s) => !bookedSlots.contains(s)).toList();
                  if (availableSlots.isNotEmpty) {
                    selectedSlot = availableSlots.first;
                  }
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Slot booked successfully!'),
                    backgroundColor: AppColors.neonGreen,
                  ),
                );
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBikeConnected = _bleState == BleConnectionState.connected;
    final bool isSelectedSlotBooked = bookedSlots.contains(selectedSlot);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.stationTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.neonGreen),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Charging Rate',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.rate,
                                style: const TextStyle(
                                  color: AppColors.neonGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.ev_station,
                            color: AppColors.neonGreen,
                            size: 36,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sun / Moon Arc Widget
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const SunMoonArcWidget(),
                    ),

                    const SizedBox(height: 20),

                    // E-Bike Bluetooth Status Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBikeConnected
                            ? AppColors.neonGreen.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBikeConnected ? AppColors.neonGreen : Colors.redAccent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBikeConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: isBikeConnected ? AppColors.neonGreen : Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isBikeConnected
                                  ? 'Bike Connected (Live Battery Monitoring)'
                                  : _bleState == BleConnectionState.connecting ||
                                          _bleState == BleConnectionState.scanning
                                      ? 'Connecting to E-Bike...'
                                      : 'Bike Not Connected (Connect to stream data)',
                              style: TextStyle(
                                color: isBikeConnected ? AppColors.neonGreen : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (!isBikeConnected)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: _bleState == BleConnectionState.disconnected
                                  ? _connectToBike
                                  : null,
                              child: Text(
                                _bleState == BleConnectionState.disconnected
                                    ? 'Connect Bike'
                                    : 'Pairing...',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Battery Display Logic
                    if (isBikeConnected)
                      LiquidBatteryWidget(percentage: liveBikeBatteryPercentage)
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.amber, size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Battery Level Hidden',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Please connect Bluetooth to view live E-Bike battery status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 25),

                    const Text(
                      'Select Time Slot for Booking',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time Slots Selection List
                    SizedBox(
                      height: 55,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = timeSlots[index];
                          final isAlreadyBooked = bookedSlots.contains(slot);
                          final isSelected = selectedSlot == slot;

                          return GestureDetector(
                            onTap: isAlreadyBooked
                                ? null
                                : () => setState(() => selectedSlot = slot),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isAlreadyBooked
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : isSelected
                                        ? AppColors.neonGreen.withValues(alpha: 0.2)
                                        : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isAlreadyBooked
                                      ? Colors.redAccent
                                      : isSelected
                                          ? AppColors.neonGreen
                                          : Colors.white.withValues(alpha: 0.1),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slot,
                                    style: TextStyle(
                                      color: isAlreadyBooked
                                          ? Colors.redAccent
                                          : isSelected
                                              ? AppColors.neonGreen
                                              : Colors.white,
                                      fontWeight: isSelected || isAlreadyBooked
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                      decoration: isAlreadyBooked
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  if (isAlreadyBooked) ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      'BOOKED',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Booking Messages History
                    if (_bookedMessages.isNotEmpty) ...[
                      const Text(
                        'Booking Notifications / Messages',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookedMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _bookedMessages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.neonGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.neonGreen,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Slot Booked: ${msg['slot']}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Station: ${msg['station']} • Booked at ${msg['time']}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Fixed Bottom Booking Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelectedSlotBooked
                        ? Colors.grey
                        : AppColors.neonGreen,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSelectedSlotBooked ? null : _showPaymentDialog,
                  child: Text(
                    isSelectedSlotBooked
                        ? 'Slot Already Booked'
                        : 'Book Slot ($selectedSlot)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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