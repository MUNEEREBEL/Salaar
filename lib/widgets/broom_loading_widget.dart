// lib/widgets/broom_loading_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class BroomLoadingWidget extends StatefulWidget {
  final String? message;
  
  const BroomLoadingWidget({super.key, this.message});

  @override
  State<BroomLoadingWidget> createState() => _BroomLoadingWidgetState();
}

class _BroomLoadingWidgetState extends State<BroomLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _sweepAnimation = Tween<double>(begin: -30, end: 30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: BroomPainter(
                    sweepAngle: _sweepAnimation.value,
                    sparkleProgress: _sparkleAnimation.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          if (widget.message != null)
            Text(
              widget.message!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.darkSurface,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class BroomPainter extends CustomPainter {
  final double sweepAngle;
  final double sparkleProgress;

  BroomPainter({
    required this.sweepAngle,
    required this.sparkleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw floor line
    final floorPaint = Paint()
      ..color = AppTheme.greyColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      floorPaint,
    );

    // Save canvas state
    canvas.save();
    
    // Translate to center and rotate
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle * math.pi / 180);

    // Draw broom handle
    final handlePaint = Paint()
      ..color = AppTheme.secondaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      const Offset(0, -30),
      const Offset(0, 10),
      handlePaint,
    );

    // Draw broom bristles
    final bristlePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(i * 3.0, 10),
        Offset(i * 4.0, 25),
        bristlePaint,
      );
    }

    // Restore canvas
    canvas.restore();

    // Draw sparkles/dust particles
    final sparklePaint = Paint()
      ..color = AppTheme.successColor.withOpacity(sparkleProgress)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 + sparkleProgress * 360) * math.pi / 180;
      final radius = 40 + (sparkleProgress * 20);
      final sparklePos = Offset(
        center.dx + math.cos(angle) * radius,
        size.height * 0.7 - 10,
      );
      canvas.drawCircle(sparklePos, 2 + (sparkleProgress * 2), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(BroomPainter oldDelegate) {
    return sweepAngle != oldDelegate.sweepAngle ||
        sparkleProgress != oldDelegate.sparkleProgress;
  }
}

