import 'package:flutter/material.dart';
import 'package:mrtap/core/theme/app_colors.dart';

/// Metro Train Icon / Logo rendered in solid color.
///
/// Designed with solid geometric shapes: a metro front face with windshield,
/// headlights, track rails, and clean lines. No gradients or drop shadows.
class MetroLogo extends StatelessWidget {
  const MetroLogo({
    super.key,
    this.size = 72,
    this.color = AppColors.primary,
    this.backgroundColor = Colors.white,
    this.showBackground = true,
  });

  final double size;
  final Color color;
  final Color backgroundColor;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MetroTrainPainter(color: color),
      ),
    );

    if (!showBackground) {
      return icon;
    }

    final double padding = size * 0.28;
    return Container(
      width: size + padding * 2,
      height: size + padding * 2,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(child: icon),
    );
  }
}

class _MetroTrainPainter extends CustomPainter {
  const _MetroTrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // Train Body (rounded rect)
    final double bodyLeft = w * 0.14;
    final double bodyRight = w * 0.86;
    final double bodyTop = h * 0.08;
    final double bodyBottom = h * 0.72;
    final RRect bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom),
      Radius.circular(w * 0.16),
    );

    // Draw main body outline / fill
    // We'll draw the outer body as stroke or solid silhouette with cutout details:
    // Outer train body shell
    canvas.drawRRect(bodyRRect, stroke);

    // Windshield (upper window)
    final double winLeft = w * 0.24;
    final double winRight = w * 0.76;
    final double winTop = h * 0.18;
    final double winBottom = h * 0.42;
    final RRect winRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(winLeft, winTop, winRight, winBottom),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(winRRect, fill);

    // Headlights (two solid circles)
    final double lightY = h * 0.56;
    final double lightRadius = w * 0.055;
    canvas.drawCircle(Offset(w * 0.30, lightY), lightRadius, fill);
    canvas.drawCircle(Offset(w * 0.70, lightY), lightRadius, fill);

    // Front center indicator / grill line
    canvas.drawLine(
      Offset(w * 0.42, lightY),
      Offset(w * 0.58, lightY),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Left and right support / wheel track legs
    canvas.drawLine(
      Offset(w * 0.28, bodyBottom),
      Offset(w * 0.20, h * 0.88),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.72, bodyBottom),
      Offset(w * 0.80, h * 0.88),
      stroke,
    );

    // Rail Track sleeper line below
    canvas.drawLine(
      Offset(w * 0.12, h * 0.92),
      Offset(w * 0.88, h * 0.92),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MetroTrainPainter oldDelegate) =>
      oldDelegate.color != color;
}
