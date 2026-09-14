import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class TimeSlotPicker extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay? selectedStartTime;
  final List<TimeOfDay> unavailableSlots;
  final ValueChanged<TimeOfDay> onSlotSelected;

  const TimeSlotPicker({
    super.key,
    required this.selectedDate,
    required this.selectedStartTime,
    required this.unavailableSlots,
    required this.onSlotSelected,
  });

  // Generate 30-minute interval slots between 08:00 AM and 08:00 PM
  List<TimeOfDay> _generateTimeSlots() {
    final List<TimeOfDay> slots = [];
    for (int hour = 8; hour < 20; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      slots.add(TimeOfDay(hour: hour, minute: 30));
    }
    return slots;
  }

  bool _isSlotEqual(TimeOfDay t1, TimeOfDay t2) {
    return t1.hour == t2.hour && t1.minute == t2.minute;
  }

  @override
  Widget build(BuildContext context) {
    final allSlots = _generateTimeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Available Time Slot',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allSlots.map((slot) {
            final isUnavailable = unavailableSlots.any(
              (u) => _isSlotEqual(u, slot),
            );
            final isSelected =
                selectedStartTime != null &&
                _isSlotEqual(selectedStartTime!, slot);

            Color backgroundColor = AppColors.surface;
            Color textColor = AppColors.textPrimary;

            if (isUnavailable) {
              backgroundColor = Colors.grey.withValues(alpha: 0.2);
              textColor = Colors.grey;
            } else if (isSelected) {
              backgroundColor = AppColors.neonGreen;
              textColor = AppColors.background;
            }

            return InkWell(
              onTap: isUnavailable ? null : () => onSlotSelected(slot),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: AppColors.neonGreen, width: 2)
                      : Border.all(color: Colors.white10),
                ),
                child: Text(
                  slot.format(context),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    decoration: isUnavailable
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
