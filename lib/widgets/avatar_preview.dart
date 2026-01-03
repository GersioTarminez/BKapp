import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/avatar_profile.dart';

class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    super.key,
    required this.profile,
    this.size = 180,
  });

  final AvatarProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: CustomPaint(
        painter: _AvatarPainter(profile),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.profile);

  final AvatarProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bodyTop = size.height * 0.55;
    final faceColor = profile.skinColorValue;

    _drawBody(canvas, size, bodyTop);
    _drawNeck(canvas, size, faceColor);
    _drawHair(canvas, size);
    _drawFace(canvas, size, faceColor);
    _drawExpression(canvas, size);
    _drawShoes(canvas, size);
    _drawCompanion(canvas, size);
  }

  void _drawBody(Canvas canvas, Size size, double bodyTop) {
    final shirtPaint = Paint()..color = profile.shirtColorValue;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        bodyTop,
        size.width * 0.56,
        size.height * 0.3,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(bodyRect, shirtPaint);

    if (profile.shirtType == 'stripe') {
      final stripePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 4;
      for (var y = bodyTop + 8; y < bodyTop + size.height * 0.28; y += 16) {
        canvas.drawLine(
          Offset(size.width * 0.24, y),
          Offset(size.width * 0.76, y),
          stripePaint,
        );
      }
    } else if (profile.shirtType == 'hoodie') {
      final hoodiePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.4, bodyTop + 8),
        Offset(size.width * 0.4, bodyTop - 8),
        hoodiePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.6, bodyTop + 8),
        Offset(size.width * 0.6, bodyTop - 8),
        hoodiePaint,
      );
    }
  }

  void _drawNeck(Canvas canvas, Size size, Color faceColor) {
    final neckPaint = Paint()..color = faceColor.withOpacity(0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.55),
          width: size.width * 0.2,
          height: size.height * 0.08,
        ),
        const Radius.circular(8),
      ),
      neckPaint,
    );
  }

  void _drawFace(Canvas canvas, Size size, Color faceColor) {
    final facePaint = Paint()..color = faceColor;
    switch (profile.faceType) {
      case 'oval':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.35),
            width: size.width * 0.45,
            height: size.height * 0.42,
          ),
          facePaint,
        );
        break;
      case 'square':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height * 0.35),
              width: size.width * 0.44,
              height: size.height * 0.4,
            ),
            const Radius.circular(24),
          ),
          facePaint,
        );
        break;
      case 'round':
      default:
        canvas.drawCircle(
          Offset(size.width / 2, size.height * 0.35),
          size.width * 0.22,
          facePaint,
        );
        break;
    }

    final eyePaint = Paint()..color = const Color(0xFF4A6FA5);
    final eyeY = size.height * 0.32;
    final eyeOffset = size.width * 0.1;
    canvas.drawCircle(Offset(size.width / 2 - eyeOffset, eyeY), 4, eyePaint);
    canvas.drawCircle(Offset(size.width / 2 + eyeOffset, eyeY), 4, eyePaint);
  }

  void _drawHair(Canvas canvas, Size size) {
    final pintura = Paint()..color = profile.hairColorValue;
    final inicioY = size.height * 0.18;
    final centro = Offset(size.width / 2, size.height * 0.3);
    Path trazo;

    switch (profile.hairType) {
      case 'long':
        trazo = Path()
          ..moveTo(size.width * 0.15, inicioY + 10)
          ..quadraticBezierTo(size.width * 0.05, size.height * 0.45,
              size.width * 0.2, size.height * 0.6)
          ..quadraticBezierTo(size.width * 0.5, size.height * 0.75,
              size.width * 0.8, size.height * 0.6)
          ..quadraticBezierTo(size.width * 0.95, size.height * 0.4,
              size.width * 0.85, inicioY + 8)
          ..quadraticBezierTo(
              size.width * 0.65, inicioY - 20, size.width * 0.35, inicioY - 12)
          ..quadraticBezierTo(
              size.width * 0.2, inicioY - 5, size.width * 0.15, inicioY + 10)
          ..close();
        canvas.drawPath(trazo, pintura);
        break;
      case 'curly':
        final base = Path();
        for (int i = 0; i < 6; i++) {
          final progreso = i / 5;
          final centroX = lerpDouble(size.width * 0.2, size.width * 0.8, progreso)!;
          final radio = size.width * 0.12;
          base.addOval(
            Rect.fromCircle(
              center: Offset(centroX, inicioY + 25 + (i.isEven ? 6 : -4)),
              radius: radio,
            ),
          );
        }
        final nube = Path()
          ..addPath(base, Offset.zero)
          ..addOval(
            Rect.fromCircle(center: centro.translate(0, -20), radius: size.width * 0.28),
          );
        canvas.drawPath(nube, pintura);
        break;
      case 'pony':
        trazo = Path()
          ..moveTo(size.width * 0.2, inicioY + 5)
          ..quadraticBezierTo(
              size.width * 0.25, inicioY - 25, size.width * 0.5, inicioY - 30)
          ..quadraticBezierTo(
              size.width * 0.8, inicioY - 25, size.width * 0.8, inicioY + 5)
          ..quadraticBezierTo(
              size.width * 0.82, size.height * 0.42, size.width * 0.65, size.height * 0.46)
          ..quadraticBezierTo(
              size.width * 0.35, size.height * 0.4, size.width * 0.2, inicioY + 5)
          ..close();
        canvas.drawPath(trazo, pintura);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.83, size.height * 0.47),
            width: size.width * 0.25,
            height: size.height * 0.25,
          ),
          pintura,
        );
        break;
      case 'straight':
        trazo = Path()
          ..moveTo(size.width * 0.2, inicioY + 5)
          ..quadraticBezierTo(size.width * 0.25, inicioY - 20,
              size.width * 0.5, inicioY - 25)
          ..quadraticBezierTo(size.width * 0.75, inicioY - 20,
              size.width * 0.8, inicioY + 5)
          ..quadraticBezierTo(size.width * 0.78, size.height * 0.45,
              size.width * 0.5, size.height * 0.5)
          ..quadraticBezierTo(size.width * 0.22, size.height * 0.46,
              size.width * 0.2, inicioY + 5)
          ..close();
        canvas.drawPath(trazo, pintura);
        break;
      case 'bald':
        return;
      case 'short':
      default:
        trazo = Path()
          ..moveTo(size.width * 0.22, inicioY + 12)
          ..quadraticBezierTo(size.width * 0.3, inicioY - 15,
              size.width * 0.5, inicioY - 18)
          ..quadraticBezierTo(size.width * 0.7, inicioY - 15,
              size.width * 0.78, inicioY + 12)
          ..quadraticBezierTo(size.width * 0.6, size.height * 0.28,
              size.width * 0.5, size.height * 0.32)
          ..quadraticBezierTo(size.width * 0.4, size.height * 0.28,
              size.width * 0.22, inicioY + 12)
          ..close();
        canvas.drawPath(trazo, pintura);
        break;
    }
  }

  void _drawExpression(Canvas canvas, Size size) {
    final mouthPaint = Paint()
      ..color = const Color(0xFFB56576)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final mouthY = size.height * 0.41;
    switch (profile.expression) {
      case 'happy':
        final rectFeliz = Rect.fromCenter(
          center: Offset(size.width / 2, mouthY + 10),
          width: size.width * 0.2,
          height: size.height * 0.3,
        );
        canvas.drawArc(rectFeliz, 0, pi, false, mouthPaint);
        break;
      case 'neutral':
        canvas.drawLine(
          Offset(size.width / 2 - size.width * 0.08, mouthY),
          Offset(size.width / 2 + size.width * 0.08, mouthY),
          mouthPaint,
        );
        break;
      case 'smile':
      default:
        final rectSonrisa = Rect.fromCenter(
          center: Offset(size.width / 2, mouthY + 6),
          width: size.width * 0.18,
          height: size.height * 0.2,
        );
        canvas.drawArc(rectSonrisa, 0, pi * 0.8, false, mouthPaint);
        break;
    }
  }

  void _drawShoes(Canvas canvas, Size size) {
    final shoesPaint = Paint()..color = profile.shoesColorValue;
    final baseY = size.height * 0.85;
    final width = size.width * 0.22;
    final height = size.height * 0.08;

    if (profile.shoesType == 'boots') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2 - width / 2, baseY),
            width: width * 0.9,
            height: height,
          ),
          const Radius.circular(8),
        ),
        shoesPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2 + width / 2, baseY),
            width: width * 0.9,
            height: height,
          ),
          const Radius.circular(8),
        ),
        shoesPaint,
      );
    } else if (profile.shoesType == 'sneakers') {
      final toePaint = Paint()..color = Colors.white.withOpacity(0.8);
      for (final offset in [-width / 2, width / 2]) {
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2 + offset, baseY),
          width: width,
          height: height * 0.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          shoesPaint,
        );
        canvas.drawCircle(
          Offset(size.width / 2 + offset, baseY + height * 0.2),
          width * 0.25,
          toePaint,
        );
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 - width / 2, baseY),
          width: width,
          height: height * 0.6,
        ),
        shoesPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2 + width / 2, baseY),
          width: width,
          height: height * 0.6,
        ),
        shoesPaint,
      );
    }
  }

  void _drawCompanion(Canvas canvas, Size size) {
    final groundY = size.height * 0.98;
    final baseX = size.width * 0.7;
    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.85);

    switch (profile.companionType) {
      case 'cat':
        bodyPaint.color = const Color(0xFFD8C3FF);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(baseX, groundY - 20),
            width: 36,
            height: 32,
          ),
          bodyPaint,
        );
        canvas.drawCircle(
          Offset(baseX, groundY - 40),
          12,
          bodyPaint,
        );
        final earPaint = Paint()..color = const Color(0xFFC3A0F3);
        canvas.drawPath(
          Path()
            ..moveTo(baseX - 10, groundY - 46)
            ..lineTo(baseX - 18, groundY - 60)
            ..lineTo(baseX - 4, groundY - 50),
          earPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(baseX + 10, groundY - 46)
            ..lineTo(baseX + 18, groundY - 60)
            ..lineTo(baseX + 4, groundY - 50),
          earPaint,
        );
        final eyeCenter = Offset(baseX, groundY - 42);
        _drawCompanionFace(canvas, eyeCenter, 6, 4);
        break;
      case 'hamster':
        bodyPaint.color = const Color(0xFFFFE5B4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(baseX, groundY - 18),
              width: 32,
              height: 36,
            ),
            const Radius.circular(16),
          ),
          bodyPaint,
        );
        canvas.drawCircle(
          Offset(baseX - 8, groundY - 40),
          9,
          bodyPaint,
        );
        canvas.drawCircle(
          Offset(baseX + 8, groundY - 40),
          9,
          bodyPaint,
        );
        final eyeCenter = Offset(baseX, groundY - 34);
        _drawCompanionFace(canvas, eyeCenter, 6, 6);
        break;
      case 'dog':
      default:
        bodyPaint.color = const Color(0xFFBFA087);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(baseX, groundY - 18),
            width: 42,
            height: 28,
          ),
          bodyPaint,
        );
        canvas.drawCircle(
          Offset(baseX + 14, groundY - 32),
          12,
          bodyPaint,
        );
        final earPaint = Paint()..color = const Color(0xFF9E8167);
        canvas.drawCircle(
          Offset(baseX + 20, groundY - 36),
          6,
          earPaint,
        );
        canvas.drawCircle(
          Offset(baseX + 8, groundY - 36),
          6,
          earPaint,
        );
        final eyeCenter = Offset(baseX + 14, groundY - 32);
        _drawCompanionFace(canvas, eyeCenter, 4, 0);
        break;
    }
  }

  void _drawCompanionFace(
    Canvas canvas,
    Offset center,
    double eyeOffset,
    double noseOffsetX,
  ) {
    final eyePaint = Paint()..color = const Color(0xFF4A6FA5);
    canvas.drawCircle(
      center.translate(-eyeOffset, 0),
      2.2,
      eyePaint,
    );
    canvas.drawCircle(
      center.translate(eyeOffset, 0),
      2.2,
      eyePaint,
    );
    canvas.drawCircle(
      center.translate(noseOffsetX, 6),
      2.8,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.profile != profile;
  }
}
