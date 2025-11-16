import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class BubbleCalmScreen extends StatefulWidget {
  const BubbleCalmScreen({super.key});

  @override
  State<BubbleCalmScreen> createState() => _BubbleCalmScreenState();
}

class _BubbleCalmScreenState extends State<BubbleCalmScreen> {
  final List<_Burbuja> _burbujas = [];
  final Random _random = Random();
  Timer? _timer;
  Size _screenSize = Size.zero;
  int _contadorBurbujas = 0;

  @override
  void initState() {
    super.initState();
    _crearBurbujas();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      _actualizarBurbujas();
    });
  }

  void _crearBurbujas() {
    for (var i = 0; i < 14; i++) {
      _burbujas.add(
        _Burbuja(
          x: 0,
          y: 0,
          size: 40 + _random.nextDouble() * 30,
          speed: 0.8 + _random.nextDouble() * 1.4,
        ),
      );
    }
  }

  void _actualizarBurbujas() {
    if (_screenSize == Size.zero) return;
    setState(() {
      for (final burbuja in _burbujas) {
        if (burbuja.estaExplotando) {
          burbuja.avanceExplosion += 0.05;
          if (burbuja.avanceExplosion >= 1) {
            _reiniciarBurbuja(burbuja);
          }
          continue;
        }

        burbuja.y -= burbuja.speed;
        if (burbuja.y + burbuja.size < 0) {
          _reiniciarBurbuja(burbuja);
        }
      }
    });
  }

  void _reiniciarBurbuja(_Burbuja burbuja) {
    burbuja
      ..size = 40 + _random.nextDouble() * 40
      ..speed = 0.8 + _random.nextDouble() * 1.6
      ..x = _random.nextDouble() *
          max(0, _screenSize.width - burbuja.size - 16) +
          8
      ..y = _screenSize.height + _random.nextDouble() * 200
      ..estaExplotando = false
      ..avanceExplosion = 0;
  }

  void _explotarBurbuja(_Burbuja burbuja) {
    if (burbuja.estaExplotando) return;
    setState(() {
      _contadorBurbujas++;
      burbuja
        ..estaExplotando = true
        ..avanceExplosion = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    if (_burbujas.any((burbuja) => burbuja.y == 0 && burbuja.x == 0)) {
      for (final burbuja in _burbujas) {
        if (burbuja.x == 0 && burbuja.y == 0) {
          _reiniciarBurbuja(burbuja);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Calm'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFBFD7FF),
        child: Stack(
          children: [
            Positioned(
              top: 30,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Burbujas explotadas: $_contadorBurbujas',
                  style: const TextStyle(
                    color: Color(0xFF4A6FA5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ..._burbujas.map((burbuja) {
              return Positioned(
                left: burbuja.x,
                top: burbuja.y,
                child: GestureDetector(
                  onTap: () => _explotarBurbuja(burbuja),
                  child: Opacity(
                    opacity: burbuja.estaExplotando
                        ? max(0, 1 - burbuja.avanceExplosion)
                        : 1,
                    child: Transform.scale(
                      scale: burbuja.estaExplotando
                          ? 1 + burbuja.avanceExplosion * 0.3
                          : 1,
                      child: Container(
                        width: burbuja.size,
                        height: burbuja.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.35),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tap a bubble to let it float away.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja {
  _Burbuja({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });

  double x;
  double y;
  double size;
  double speed;
  bool estaExplotando = false;
  double avanceExplosion = 0;
}
