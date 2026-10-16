import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative animated solid geometric shapes (SVG-style flat vector shapes).
///
/// Draws floating solid geometric shapes (hexagons, rings, diamonds, dots, dashes)
/// with subtle continuous rotation and floating offset. Strictly solid colors,
/// no gradients and no drop shadows.
class GeometricBackgroundShapes extends StatefulWidget {
  const GeometricBackgroundShapes({
    super.key,
    required this.baseColor,
    this.opacity = 0.08,
  });

  final Color baseColor;
  final double opacity;

  @override
  State<GeometricBackgroundShapes> createState() =>
      _GeometricBackgroundShapesState();
}

class _GeometricBackgroundShapesState extends State<GeometricBackgroundShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ShapesPainter(
            progress: _controller.value,
            color: widget.baseColor.withValues(alpha: widget.opacity),
          ),
        );
      },
    );
  }
}

class _ShapesPainter extends CustomPainter {
  const _ShapesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double t = progress * 2 * math.pi;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Top-left rotating diamond
    final double d1X = w * 0.15 + math.sin(t) * 12;
    final double d1Y = h * 0.18 + math.cos(t) * 12;
    _drawPolygon(canvas, Offset(d1X, d1Y), 24, 4, t, stroke);

    // 2. Top-right solid small circle with orbiting ring
    final double c1X = w * 0.85 + math.cos(t * 0.8) * 10;
    final double c1Y = h * 0.14 + math.sin(t * 0.8) * 10;
    canvas.drawCircle(Offset(c1X, c1Y), 8, fill);
    canvas.drawCircle(Offset(c1X, c1Y), 26, stroke);

    // 3. Middle-left solid regular hexagon
    final double h1X = w * 0.10 + math.cos(t * 0.6) * 14;
    final double h1Y = h * 0.48 + math.sin(t * 0.6) * 14;
    _drawPolygon(canvas, Offset(h1X, h1Y), 28, 6, -t * 0.7, stroke);

    // 4. Middle-right solid angled plus/cross
    final double p1X = w * 0.90 + math.sin(t * 0.9) * 10;
    final double p1Y = h * 0.52 + math.cos(t * 0.9) * 10;
    _drawCross(canvas, Offset(p1X, p1Y), 18, t * 0.5, stroke);

    // 5. Bottom-left triangle
    final double trX = w * 0.18 + math.sin(t * 0.7) * 12;
    final double trY = h * 0.80 + math.cos(t * 0.7) * 12;
    _drawPolygon(canvas, Offset(trX, trY), 20, 3, t * 0.8, stroke);

    // 6. Bottom-right concentric rings
    final double r1X = w * 0.82 + math.cos(t * 0.5) * 12;
    final double r1Y = h * 0.78 + math.sin(t * 0.5) * 12;
    canvas.drawCircle(Offset(r1X, r1Y), 16, stroke);
    canvas.drawCircle(Offset(r1X, r1Y), 5, fill);

    // 7. Subtle floating dots grid
    _drawDot(canvas, Offset(w * 0.32, h * 0.10 + math.sin(t) * 6), 3.5, fill);
    _drawDot(canvas, Offset(w * 0.68, h * 0.28 + math.cos(t) * 6), 4.0, fill);
    _drawDot(canvas, Offset(w * 0.25, h * 0.65 + math.sin(t * 1.2) * 8), 3.5, fill);
    _drawDot(canvas, Offset(w * 0.75, h * 0.64 + math.cos(t * 1.2) * 8), 4.5, fill);
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    double angleOffset,
    Paint paint,
  ) {
    final Path path = Path();
    for (int i = 0; i < sides; i++) {
      final double angle = (2 * math.pi / sides) * i + angleOffset;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCross(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset(-size, 0), Offset(size, 0), paint);
    canvas.drawLine(Offset(0, -size), Offset(0, size), paint);
    canvas.restore();
  }

  void _drawDot(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Animated metro radar/pulse rings behind the metro logo or NFC scanner.
/// Solid concentric rings that expand smoothly, with strict solid colors and zero drop shadow.
class AnimatedSolidRadarRings extends StatelessWidget {
  const AnimatedSolidRadarRings({
    super.key,
    required this.progress,
    required this.color,
    this.size = 220,
    this.strokeWidth = 2.0,
  });

  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SolidRadarPainter(
          progress: progress,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SolidRadarPainter extends CustomPainter {
  const _SolidRadarPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final double ringProgress = (progress + (i / 3.0)) % 1.0;
      final double radius = maxRadius * (0.45 + 0.55 * ringProgress);
      // Fade stroke opacity smoothly without blur or shadow
      final double alpha = (1.0 - ringProgress).clamp(0.0, 1.0);
      final Paint stroke = Paint()
        ..color = color.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      canvas.drawCircle(center, radius, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SolidRadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
