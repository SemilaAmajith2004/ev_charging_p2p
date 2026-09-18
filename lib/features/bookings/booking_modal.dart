import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';
import '../payment/payment_screen.dart';

class BookingModal extends StatefulWidget {
  const BookingModal({super.key, required this.pricePerKwh});

  final double pricePerKwh;

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  DateTime _selectedDate = DateTime.now();
  String _selectedDateMode = 'Today';
  String? _selectedSlot;

  final List<Map<String, dynamic>> _timeSlots = [
    {'label': '08:00 AM - 10:00 AM', 'available': true},
    {'label': '10:30 AM - 12:30 PM', 'available': false},
    {'label': '01:00 PM - 03:00 PM', 'available': true},
    {'label': '03:30 PM - 05:30 PM', 'available': true},
    {'label': '06:00 PM - 08:00 PM', 'available': false},
    {'label': '08:30 PM - 10:30 PM', 'available': true},
  ];

  double get _estimatedDurationHours {
    if (_selectedSlot == null) return 2.0;

    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s?(AM|PM)\s?-\s?(\d{1,2}):(\d{2})\s?(AM|PM)',
    ).firstMatch(_selectedSlot!);

    if (match == null) return 2.0;

    final start = _parseTime(match.group(1)!, match.group(2)!, match.group(3)!);
    final end = _parseTime(match.group(4)!, match.group(5)!, match.group(6)!);
    final diff = end.difference(start).inMinutes / 60;
    return diff > 0 ? diff : 2.0;
  }

  double get _estimatedCost {
    return _estimatedDurationHours * widget.pricePerKwh;
  }

  DateTime _parseTime(String hour, String minute, String period) {
    var hourValue = int.parse(hour);
    final minuteValue = int.parse(minute);

    if (period.toUpperCase() == 'PM' && hourValue != 12) {
      hourValue += 12;
    }
    if (period.toUpperCase() == 'AM' && hourValue == 12) {
      hourValue = 0;
    }

    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hourValue,
      minuteValue,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonGreen,
              secondary: AppColors.neonGreen,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDateMode = 'Custom';
      });
    }
  }

  String _formatDate(DateTime date) {
    if (date.day == DateTime.now().day) {
      return 'Today';
    }
    if (date.day == DateTime.now().add(const Duration(days: 1)).day) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmBooking() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SafeArea(
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book a Charging Slot',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              'Date',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Today'),
                    selected: _selectedDateMode == 'Today',
                    onSelected: (_) {
                      setState(() {
                        _selectedDateMode = 'Today';
                        _selectedDate = DateTime.now();
                      });
                    },
                    selectedColor: AppColors.neonGreen,
                    labelStyle: TextStyle(
                      color: _selectedDateMode == 'Today'
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Tomorrow'),
                    selected: _selectedDateMode == 'Tomorrow',
                    onSelected: (_) {
                      setState(() {
                        _selectedDateMode = 'Tomorrow';
                        _selectedDate = DateTime.now().add(
                          const Duration(days: 1),
                        );
                      });
                    },
                    selectedColor: AppColors.neonGreen,
                    labelStyle: TextStyle(
                      color: _selectedDateMode == 'Tomorrow'
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pick Date'),
                    selected: _selectedDateMode == 'Custom',
                    onSelected: (_) => _pickDate(),
                    selectedColor: AppColors.neonGreen,
                    labelStyle: TextStyle(
                      color: _selectedDateMode == 'Custom'
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            const Text(
              'Available Time Slots',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _timeSlots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final available = slot['available'] as bool;
                  final isSelected = _selectedSlot == slot['label'];

                  return GestureDetector(
                    onTap: available
                        ? () => setState(() => _selectedSlot = slot['label'])
                        : null,
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.neonGreen.withValues(alpha: 0.18)
                            : available
                            ? AppColors.surface
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.neonGreen
                              : available
                              ? Colors.white12
                              : Colors.white10,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot['label'],
                            style: TextStyle(
                              color: available
                                  ? AppColors.textPrimary
                                  : Colors.white38,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            available ? 'Available' : 'Booked',
                            style: TextStyle(
                              color: available
                                  ? AppColors.neonGreen
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101713),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Cost',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'LKR ${_estimatedCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_estimatedDurationHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
