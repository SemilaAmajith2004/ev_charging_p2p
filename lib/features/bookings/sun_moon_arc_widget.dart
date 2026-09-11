import 'dart:async';
import 'package:flutter/material.dart';

class SunMoonArcWidget extends StatefulWidget {
  const SunMoonArcWidget({super.key});

  @override
  State<SunMoonArcWidget> createState() => _SunMoonArcWidgetState();
}

class _SunMoonArcWidgetState extends State<SunMoonArcWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int hour = _currentTime.hour;
    final int minute = _currentTime.minute;
    final double totalMinutes = hour * 60.0 + minute;

    // Day Time: 06:00 AM - 06:00 PM
    final bool isDay = hour >= 6 && hour < 18;
    double progress;

    if (isDay) {
      progress = ((totalMinutes - 360) / 720).clamp(0.0, 1.0);
    } else {
      double nightMins = hour >= 18 ? (totalMinutes - 1080) : (totalMinutes + 360);
      progress = (nightMins / 720).clamp(0.0, 1.0);
    }

    final String timeStr =
        "${_currentTime.hour % 12 == 0 ? 12 : _currentTime.hour % 12}:${_currentTime.minute.toString().padLeft(2, '0')} ${_currentTime.hour >= 12 ? 'PM' : 'AM'}";

    final Color activeColor = isDay ? const Color(0xFFFFB703) : const Color(0xFF00E5FF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: activeColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'REAL-TIME: $timeStr',
              style: TextStyle(
                color: activeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          width: double.infinity,
          child: CustomPaint(
            painter: SunMoonArcPainter(
              progress: progress,
              isDay: isDay,
              activeColor: activeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class SunMoonArcPainter extends CustomPainter {
  final double progress;
  final bool isDay;
  final Color activeColor;

  SunMoonArcPainter({
    required this.progress,
    required this.isDay,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Single Curved Arc Path
    final Path arcPath = Path();
    arcPath.moveTo(20, h - 15);
    arcPath.quadraticBezierTo(w / 2, 5, w - 20, h - 15);

    final Paint linePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(arcPath, linePaint);

    // 2. Exact Position Calculation along Bezier Curve
    final double t = progress;
    final double cx = (1 - t) * (1 - t) * 20 + 2 * (1 - t) * t * (w / 2) + t * t * (w - 20);
    final double cy = (1 - t) * (1 - t) * (h - 15) + 2 * (1 - t) * t * (5) + t * t * (h - 15);

    // 3. Glowing Background Aura behind Sun/Moon
    canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 4. Draw Sun or Moon Icon
    if (isDay) {
      _drawSun(canvas, Offset(cx, cy), activeColor);
    } else {
      _drawCrescentMoon(canvas, Offset(cx, cy), activeColor);
    }
  }

  // Draw Sun Vector
  void _drawSun(Canvas canvas, Offset center, Color color) {
    final Paint sunPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Center Core
    canvas.drawCircle(center, 7, sunPaint);

    // Sun Rays
    final Paint rayPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const double rayLength = 4.0;
    const double rayDistance = 10.0;

    for (int i = 0; i < 8; i++) {
      final double angle = (i * 45) * 3.1415926535897932 / 180;
      final Offset start = Offset(
        center.dx + rayDistance * _cos(angle),
        center.dy + rayDistance * _sin(angle),
      );
      final Offset end = Offset(
        center.dx + (rayDistance + rayLength) * _cos(angle),
        center.dy + (rayDistance + rayLength) * _sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }
  }

  // Draw Crescent Moon Vector
  void _drawCrescentMoon(Canvas canvas, Offset center, Color color) {
    final Paint moonPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path moonPath = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: 9)),
      Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(center.dx - 3.5, center.dy - 3.5),
            radius: 8.5,
          ),
        ),
    );

    canvas.drawPath(moonPath, moonPaint);
  }

  double _cos(double radians) => double.parse((radians).toString()) == 0 ? 1 : (radians == 3.1415926535897932 ? -1 : (radians == 1.5707963267948966 || radians == 4.71238898038469 ? 0 : _approxCos(radians)));
  double _sin(double radians) => _approxSin(radians);

  double _approxCos(double rad) {
    return 1 - (rad * rad) / 2 + (rad * rad * rad * rad) / 24;
  }

  double _approxSin(double rad) {
    return rad - (rad * rad * rad) / 6 + (rad * rad * rad * rad * rad) / 120;
  }

  @override
  bool shouldRepaint(covariant SunMoonArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDay != isDay ||
      oldDelegate.activeColor != activeColor;
}