import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom loader widget themed for Mahmood Pharmacy app
/// Features a medical cross with pulsing animation
class PharmacyLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const PharmacyLoader({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  State<PharmacyLoader> createState() => _PharmacyLoaderState();
}

class _PharmacyLoaderState extends State<PharmacyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PharmacyLoaderPainter(
                color: effectiveColor,
                strokeWidth: widget.strokeWidth,
                progress: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PharmacyLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  _PharmacyLoaderPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // Draw the circular background
    canvas.drawCircle(
      center,
      radius,
      paint..color = color.withValues(alpha: 0.2),
    );

    // Draw the animated arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );

    // Draw the medical cross in the center
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crossSize = size.width * 0.35;
    final crossThickness = crossSize * 0.3;

    // Vertical bar of cross
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: crossThickness,
          height: crossSize,
        ),
        Radius.circular(crossThickness / 2),
      ),
      crossPaint,
    );

    // Horizontal bar of cross
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: crossSize,
          height: crossThickness,
        ),
        Radius.circular(crossThickness / 2),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_PharmacyLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A simpler pharmacy-themed loader with pills animation
class PharmacyPillLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const PharmacyPillLoader({super.key, this.size = 50.0, this.color});

  @override
  State<PharmacyPillLoader> createState() => _PharmacyPillLoaderState();
}

class _PharmacyPillLoaderState extends State<PharmacyPillLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final adjustedValue = (_controller.value + delay) % 1.0;
              final scale = math.sin(adjustedValue * math.pi);

              return Positioned(
                left: widget.size / 2 - 6,
                top: widget.size / 2 - 6 + (index - 1) * 12,
                child: Transform.scale(
                  scale: 0.5 + (scale * 0.5),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(
                        alpha: 0.3 + (scale * 0.7),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
