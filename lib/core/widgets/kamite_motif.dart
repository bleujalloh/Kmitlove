import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Identité visuelle de marque : disque solaire, pyramides et frise
/// géométrique inspirés des motifs kémites — dessin vectoriel maison
/// (CustomPainter), pas une photo ou une image générique. Utilisé en
/// vitrine sur l'onboarding et en rappel de marque sur les écrans
/// d'authentification.
class KamiteMotif extends StatelessWidget {
  const KamiteMotif({super.key, this.height = 200, this.compact = false});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _KamiteMotifPainter(compact: compact)),
    );
  }
}

class _KamiteMotifPainter extends CustomPainter {
  _KamiteMotifPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = AppColors.ink;
    final accent = Paint()..color = AppColors.accent;
    final soft = Paint()..color = AppColors.accentSoft;

    final centerX = size.width / 2;
    final sunCenterY = size.height * (compact ? 0.42 : 0.34);
    final sunRadius = size.height * (compact ? 0.26 : 0.18);

    // Disque solaire (Rê) : cercle plein entouré de rayons courts.
    canvas.drawCircle(Offset(centerX, sunCenterY), sunRadius, accent);
    final rayPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = compact ? 2.5 : 3
      ..strokeCap = StrokeCap.round;
    const rayCount = 12;
    for (var i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi / rayCount) * i;
      final innerR = sunRadius * 1.25;
      final outerR = sunRadius * 1.55;
      canvas.drawLine(
        Offset(centerX + innerR * math.cos(angle), sunCenterY + innerR * math.sin(angle)),
        Offset(centerX + outerR * math.cos(angle), sunCenterY + outerR * math.sin(angle)),
        rayPaint,
      );
    }

    if (!compact) {
      // Silhouette de trois pyramides sous le disque, posées sur une ligne
      // d'horizon fine.
      final baseY = size.height * 0.86;
      final horizonPaint = Paint()
        ..color = AppColors.border
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), horizonPaint);

      _drawPyramid(canvas, Offset(centerX, baseY), size.height * 0.26, ink);
      _drawPyramid(canvas, Offset(centerX - size.height * 0.34, baseY), size.height * 0.17, soft);
      _drawPyramid(canvas, Offset(centerX + size.height * 0.34, baseY), size.height * 0.17, soft);

      // Frise géométrique (inspirée des motifs adinkra/méandres) en bas.
      final friezeY = size.height * 0.95;
      final friezePaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final step = 18.0;
      var x = (size.width % step) / 2;
      while (x < size.width) {
        final path = Path()
          ..moveTo(x, friezeY)
          ..lineTo(x + step / 2, friezeY - 7)
          ..lineTo(x + step, friezeY);
        canvas.drawPath(path, friezePaint);
        x += step;
      }
    }
  }

  void _drawPyramid(Canvas canvas, Offset base, double h, Paint paint) {
    final w = h * 1.1;
    final path = Path()
      ..moveTo(base.dx, base.dy - h)
      ..lineTo(base.dx - w / 2, base.dy)
      ..lineTo(base.dx + w / 2, base.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _KamiteMotifPainter oldDelegate) => oldDelegate.compact != compact;
}
