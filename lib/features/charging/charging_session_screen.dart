import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';

class ChargingSessionScreen extends StatefulWidget {
  const ChargingSessionScreen({super.key});

  @override
  State<ChargingSessionScreen> createState() => _ChargingSessionScreenState();
}

class _ChargingSessionScreenState extends State<ChargingSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  Timer? _sessionTimer;
  double _batteryPercent = 48;
  double _energyConsumed = 11.8;
  double _chargingSpeed = 18.4;
  double _elapsedSeconds = 0;
  double _currentBill = 320.0;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;
        _batteryPercent = (_batteryPercent + 0.6).clamp(0, 100).toDouble();
        _energyConsumed = (_energyConsumed + 0.18).toDouble();
        _chargingSpeed = (18.4 - (_batteryPercent / 100) * 3.5).clamp(4, 22);
        _currentBill = (_currentBill + 11.5).toDouble();
      });

      if (_batteryPercent >= 100) {
        timer.cancel();
        _showCompletionDialog();
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  String get _elapsedTime {
    final minutes = (_elapsedSeconds / 60).floor();
    final seconds = (_elapsedSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showStopChargingDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101713),
        title: const Text(
          'Stop Charging?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your session will end immediately and a receipt will be generated.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Stop Session',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _sessionTimer?.cancel();
      _showCompletionDialog(isManualStop: true);
    }
  }

  void _showCompletionDialog({bool isManualStop = false}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101713),
        title: Text(
          isManualStop ? 'Charging Session Ended' : 'Session Complete',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Charging receipt',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _receiptRow('Battery', '${_batteryPercent.toStringAsFixed(0)}%'),
            _receiptRow(
              'Energy Used',
              '${_energyConsumed.toStringAsFixed(1)} kWh',
            ),
            _receiptRow('Duration', _elapsedTime),
            _receiptRow('Total Bill', 'LKR ${_currentBill.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Charging Session',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  _waveController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return _BatteryRing(
                    progress: _batteryPercent / 100,
                    wavePhase: _waveController.value * 2 * math.pi,
                    pulse: _pulseController.value,
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                '${_batteryPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Battery charge',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 26),

              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                children: [
                  _metricCard(
                    label: 'Energy Consumed',
                    value: '${_energyConsumed.toStringAsFixed(1)} kWh',
                    icon: Icons.battery_charging_full_rounded,
                  ),
                  _metricCard(
                    label: 'Charging Speed',
                    value: '${_chargingSpeed.toStringAsFixed(1)} kW',
                    icon: Icons.speed_rounded,
                  ),
                  _metricCard(
                    label: 'Elapsed Time',
                    value: _elapsedTime,
                    icon: Icons.timer_rounded,
                  ),
                  _metricCard(
                    label: 'Current Bill',
                    value: 'LKR ${_currentBill.toStringAsFixed(0)}',
                    icon: Icons.receipt_long_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showStopChargingDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle_rounded),
                  label: const Text(
                    'Stop Charging Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryRing extends StatelessWidget {
  const _BatteryRing({
    required this.progress,
    required this.wavePhase,
    required this.pulse,
  });

  final double progress;
  final double wavePhase;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _BatteryWavePainter(
          progress: progress,
          wavePhase: wavePhase,
          pulse: pulse,
          primary: AppColors.neonGreen,
          secondary: AppColors.solarAmber,
        ),
      ),
    );
  }
}

class _BatteryWavePainter extends CustomPainter {
  _BatteryWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.pulse,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final double wavePhase;
  final double pulse;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;
    final ringRect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, basePaint);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [primary, secondary, primary],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final wavePaint = Paint()
      ..color = primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final clipRect = Rect.fromCircle(center: center, radius: radius * 0.9);
    final clipPath = Path()..addOval(clipRect);

    canvas.save();
    canvas.clipPath(clipPath);

    final wavePath = Path();
    final amplitude = radius * 0.18 * (0.7 + pulse);
    final baseLine = center.dy + radius * 0.52;

    wavePath.moveTo(center.dx - radius * 1.1, baseLine);
    for (double x = -radius * 1.1; x <= radius * 1.1; x += 4) {
      final y =
          baseLine -
          amplitude * math.sin((x / (radius * 1.8)) * 2 * math.pi + wavePhase);
      wavePath.lineTo(center.dx + x, y);
    }
    wavePath.lineTo(center.dx + radius * 1.1, size.height + 20);
    wavePath.lineTo(center.dx - radius * 1.1, size.height + 20);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatteryWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.pulse != pulse;
  }
}
