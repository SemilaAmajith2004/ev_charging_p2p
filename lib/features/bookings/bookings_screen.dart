import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/mock_ble_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_color.dart';
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

  // Selected TimeOfDay for Clock Pickers
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  // Book වූ සියලුම Slots තබා ගන්නා List එක
  final List<String> bookedSlots = ['09:00 AM - 10:00 AM'];

  // Book කළ Slot වල Message History
  final List<Map<String, String>> _bookedMessages = [
    {
      'slot': '09:00 AM - 10:00 AM',
      'station': 'Colombo Fast Charge Station',
      'time': '08:45 AM',
    },
  ];

  StreamSubscription? _batterySub;
  StreamSubscription? _stateSub;

  String? _customSlotError;

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
            content: Text(
              'E-Bike Connected Successfully! Receiving battery data...',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    _batterySub = _bleService.batteryPercentageStream.listen((battery) {
      if (!mounted) return;
      setState(() => liveBikeBatteryPercentage = battery);

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.battery_charging_full,
                color: AppColors.neonGreen,
                size: 30,
              ),
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

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_selectedStartTime ?? TimeOfDay.now())
          : (_selectedEndTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonGreen,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customSlotError = null;
        if (isStart) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  DateTime _getBookingStartDateTime(String slot) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(slot);
    if (match == null) {
      return DateTime.now().add(const Duration(hours: 1));
    }

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;

    if (period == 'AM' && hour == 12) {
      hour = 0;
    } else if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  bool _checkSlotOverlap(int startMinutes, int endMinutes, String slotText) {
    final slotParts = slotText.split(' - ');
    if (slotParts.length != 2) return false;

    final start = _parseTimeString(slotParts[0]);
    final end = _parseTimeString(slotParts[1]);
    if (start == null || end == null) return false;

    final slotStartMinutes = start.hour * 60 + start.minute;
    final slotEndMinutes = end.hour * 60 + end.minute;

    return startMinutes < slotEndMinutes && endMinutes > slotStartMinutes;
  }

  TimeOfDay? _parseTimeString(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    if (period == 'AM' && hour == 12) {
      hour = 0;
    } else if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _validateCustomSlot() {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      return 'Please select both start and end times.';
    }

    final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;

    if (endMinutes <= startMinutes) {
      return 'End time must be later than start time.';
    }

    final customSlotText =
        '${_selectedStartTime!.format(context)} - ${_selectedEndTime!.format(context)}';

    for (final bookedSlot in bookedSlots) {
      if (_checkSlotOverlap(startMinutes, endMinutes, bookedSlot)) {
        return 'This slot overlaps with an existing booking for $bookedSlot.';
      }
    }

    if (bookedSlots.contains(customSlotText)) {
      return 'This exact slot already exists.';
    }

    return null;
  }

  bool get _isCustomSlotValid => _validateCustomSlot() == null;

  void _saveCustomSlot() {
    final error = _validateCustomSlot();
    if (error != null) {
      setState(() {
        _customSlotError = error;
      });
      return;
    }

    final String customSlot =
        '${_selectedStartTime!.format(context)} - ${_selectedEndTime!.format(context)}';
    final String currentTimeFormatted = TimeOfDay.now().format(context);

    setState(() {
      _customSlotError = null;
      bookedSlots.add(customSlot);
      _bookedMessages.insert(0, {
        'slot': customSlot,
        'station': widget.stationTitle,
        'time': currentTimeFormatted,
      });
      selectedSlot = customSlot;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom slot created successfully.'),
        backgroundColor: AppColors.neonGreen,
      ),
    );
  }

  void _cancelBooking(String slot) {
    setState(() {
      bookedSlots.remove(slot);
      _bookedMessages.removeWhere((message) => message['slot'] == slot);
      
      // Slot එක cancel කරපු ගමන් Default Available Slot එකකට Switch වෙනවා
      selectedSlot = timeSlots.firstWhere(
        (timeSlot) => !bookedSlots.contains(timeSlot),
        orElse: () => timeSlots.first,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking cancelled and removed.'),
        backgroundColor: Colors.redAccent,
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              onPressed: () async {
                Navigator.pop(dialogContext);

                final bookingStartTime = _getBookingStartDateTime(selectedSlot);
                final bookingId = 'BK_${DateTime.now().millisecondsSinceEpoch}';

                setState(() {
                  bookedSlots.add(selectedSlot);
                  _bookedMessages.insert(0, {
                    'slot': selectedSlot,
                    'station': widget.stationTitle,
                    'time': currentTimeFormatted,
                  });
                });

                await NotificationService().scheduleBookingAlerts(
                  bookingId: bookingId,
                  bookingStartTime: bookingStartTime,
                  stationName: widget.stationTitle,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
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

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: time != null ? AppColors.neonGreen : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: TextStyle(
                    color: time != null ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.access_time_filled,
              color: AppColors.neonGreen,
              size: 20,
            ),
          ],
        ),
      ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
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
                          color: isBikeConnected
                              ? AppColors.neonGreen
                              : Colors.redAccent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBikeConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: isBikeConnected
                                ? AppColors.neonGreen
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isBikeConnected
                                  ? 'Bike Connected (Live Battery Monitoring)'
                                  : _bleState ==
                                            BleConnectionState.connecting ||
                                        _bleState == BleConnectionState.scanning
                                  ? 'Connecting to E-Bike...'
                                  : 'Bike Not Connected (Connect to stream data)',
                              style: TextStyle(
                                color: isBikeConnected
                                    ? AppColors.neonGreen
                                    : Colors.redAccent,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              onPressed:
                                  _bleState == BleConnectionState.disconnected
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

                    // Battery Display
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
                            Icon(
                              Icons.lock_outline,
                              color: Colors.amber,
                              size: 40,
                            ),
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
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
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
                            
                            onTap: () => setState(() => selectedSlot = slot),
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
                                  color: isSelected
                                      ? (isAlreadyBooked ? Colors.redAccent : AppColors.neonGreen)
                                      : (isAlreadyBooked
                                          ? Colors.redAccent.withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.1)),
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

                    // Interactive Time Slot Creator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Your Own Time Slot',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePickerTile(
                                  label: 'Start Time',
                                  time: _selectedStartTime,
                                  onTap: () => _selectTime(context, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimePickerTile(
                                  label: 'End Time',
                                  time: _selectedEndTime,
                                  onTap: () => _selectTime(context, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_customSlotError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Text(
                                _customSlotError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCustomSlotValid
                                    ? AppColors.neonGreen
                                    : Colors.grey,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _isCustomSlotValid
                                  ? _saveCustomSlot
                                  : null,
                              child: const Text(
                                'SAVE SLOT',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
                                color: AppColors.neonGreen.withValues(
                                  alpha: 0.3,
                                ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                IconButton(
                                  onPressed: () => _cancelBooking(msg['slot']!),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Cancel booking',
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

            // Fixed Bottom Booking / Cancel Button Bar
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
              child: Column(
                children: [
                  if (isSelectedSlotBooked) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _cancelBooking(selectedSlot),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          'Cancel Booking ($selectedSlot)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showPaymentDialog,
                        child: Text(
                          'Book Slot ($selectedSlot)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}