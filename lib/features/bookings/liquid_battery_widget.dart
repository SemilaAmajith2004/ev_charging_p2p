import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_color.dart';

class LiquidBatteryWidget extends StatefulWidget {
  final double percentage;

  const LiquidBatteryWidget({
    super.key,
    required this.percentage,
  });

  @override
  State<LiquidBatteryWidget> createState() => _LiquidBatteryWidgetState();
}

class _LiquidBatteryWidgetState extends State<LiquidBatteryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1218),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonGreen,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.25),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(140, 200),
                        painter: BatteryLiquidPainter(
                          percentage: widget.percentage,
                          waveValue: _waveController.value,
                          color: AppColors.neonGreen,
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: widget.percentage > 0.4
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : const Color.fromARGB(255, 0, 0, 0),
                          size: 38,
                        ),
                        Text(
                          '${(widget.percentage * 100).toInt()}%',
                          style: TextStyle(
                            color: widget.percentage > 0.4
                                ? Colors.black
                                : Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'CHARGING...',
                          style: TextStyle(
                            color: widget.percentage > 0.4
                                ? Colors.black87
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BatteryLiquidPainter extends CustomPainter {
  final double percentage;
  final double waveValue;
  final Color color;

  BatteryLiquidPainter({
    required this.percentage,
    required this.waveValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillHeight = size.height * percentage;
    final baseHeight = size.height - fillHeight;

    path.moveTo(0, baseHeight);

    for (double i = 0.0; i <= size.width; i++) {
      double wave = math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * 4;
      path.lineTo(i, baseHeight + wave);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BatteryLiquidPainter oldDelegate) {
    return oldDelegate.waveValue != waveValue || oldDelegate.percentage != percentage;
  }
}