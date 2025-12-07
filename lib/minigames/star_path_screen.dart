import 'dart:math';

import 'package:flutter/material.dart';

class StarPathScreen extends StatefulWidget {
  const StarPathScreen({super.key});

  @override
  State<StarPathScreen> createState() => _StarPathScreenState();
}

class _StarPathScreenState extends State<StarPathScreen> {
  final List<_ObjetoEspacial> _objetos = [];
  _TipoObjeto _modoActual = _TipoObjeto.estrella;
  _Emocion _emocionActual = _Emocion.feliz;
  Offset? _ultimoPunto;

  void _agregarObjeto(Offset posicion) {
    final estilo = _emociones[_emocionActual]!;
    final objeto = _ObjetoEspacial(
      tipo: _modoActual,
      posicion: posicion,
      color: estilo.colores[_modoActual]!,
      tamano: estilo.tamanos[_modoActual]!,
    );
    setState(() {
      _objetos.add(objeto);
    });
  }

  void _tap(TapDownDetails detalles) {
    _agregarObjeto(detalles.localPosition);
  }

  void _panStart(DragStartDetails detalles) {
    _ultimoPunto = detalles.localPosition;
    _agregarObjeto(detalles.localPosition);
  }

  void _panUpdate(DragUpdateDetails detalles) {
    final actual = detalles.localPosition;
    if (_ultimoPunto == null ||
        (actual - _ultimoPunto!).distance > _emociones[_emocionActual]!.pasoArrastre) {
      _ultimoPunto = actual;
      _agregarObjeto(actual);
    }
  }

  void _panEnd(DragEndDetails detalles) {
    _ultimoPunto = null;
  }

  void _borrar() {
    setState(() {
      _objetos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emocionChips = _Emocion.values.map((emocion) {
      final seleccionado = emocion == _emocionActual;
      final estilo = _emociones[emocion]!;
      return ChoiceChip(
        label: Text(estilo.icono),
        selected: seleccionado,
        selectedColor: estilo.colorPrimario.withOpacity(0.8),
        backgroundColor: estilo.colorPrimario.withOpacity(0.25),
        labelStyle: TextStyle(
          fontSize: 24,
          color: seleccionado ? Colors.white : Colors.white70,
        ),
        onSelected: (_) {
          setState(() => _emocionActual = emocion);
        },
      );
    }).toList();

    final objetoChips = _TipoObjeto.values.map((tipo) {
      final seleccionado = tipo == _modoActual;
      return ChoiceChip(
        label: Text(_nombresObjeto[tipo]!),
        selected: seleccionado,
        selectedColor: Colors.white.withOpacity(0.3),
        backgroundColor: Colors.white.withOpacity(0.1),
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
        ),
        onSelected: (_) {
          setState(() => _modoActual = tipo);
        },
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Star Path'),
        backgroundColor: const Color(0xFF0F1A2B),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _objetos.isEmpty ? null : _borrar,
            child: const Text(
              'Borrar espacio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1A2B), Color(0xFF1C2B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/star_bg.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.15,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dibuja tu espacio emocional',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emocionChips,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: objetoChips,
                  ),
                ],
              ),
            ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _tap,
              onPanStart: _panStart,
              onPanUpdate: _panUpdate,
              onPanEnd: _panEnd,
              child: CustomPaint(
                painter: _EspacioPainter(objetos: _objetos),
                size: Size.infinite,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _EspacioPainter extends CustomPainter {
  _EspacioPainter({required this.objetos});

  final List<_ObjetoEspacial> objetos;

  @override
  void paint(Canvas canvas, Size size) {
    for (final objeto in objetos) {
      switch (objeto.tipo) {
        case _TipoObjeto.estrella:
          _dibujarEstrella(canvas, objeto);
          break;
        case _TipoObjeto.planeta:
          _dibujarPlaneta(canvas, objeto);
          break;
        case _TipoObjeto.asteroide:
          _dibujarAsteroide(canvas, objeto);
          break;
      }
    }
  }

  void _dibujarEstrella(Canvas canvas, _ObjetoEspacial objeto) {
    final pincel = Paint()
      ..color = objeto.color
      ..style = PaintingStyle.fill;
    final radio = objeto.tamano / 2;
    final puntos = List.generate(5, (index) {
      final angulo = (index * 72 - 90) * pi / 180;
      return Offset(
        objeto.posicion.dx + radio * cos(angulo),
        objeto.posicion.dy + radio * sin(angulo),
      );
    });
    final path = Path()..moveTo(puntos[0].dx, puntos[0].dy);
    path
      ..lineTo(puntos[2].dx, puntos[2].dy)
      ..lineTo(puntos[4].dx, puntos[4].dy)
      ..lineTo(puntos[1].dx, puntos[1].dy)
      ..lineTo(puntos[3].dx, puntos[3].dy)
      ..close();
    canvas.drawPath(path, pincel);
  }

  void _dibujarPlaneta(Canvas canvas, _ObjetoEspacial objeto) {
    final pintura = Paint()..color = objeto.color;
    canvas.drawCircle(objeto.posicion, objeto.tamano / 1.5, pintura);

    final banda = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = objeto.tamano * 0.1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: objeto.posicion,
        radius: objeto.tamano / 1.2,
      ));
    canvas.drawPath(path, banda);
  }

  void _dibujarAsteroide(Canvas canvas, _ObjetoEspacial objeto) {
    final puntos = <Offset>[];
    final lados = 6;
    final radioBase = objeto.tamano / 2;
    for (var i = 0; i < lados; i++) {
      final angulo = (i / lados) * 2 * pi;
      final distancia = radioBase * (0.8 + Random(i).nextDouble() * 0.4);
      puntos.add(
        Offset(
          objeto.posicion.dx + distancia * cos(angulo),
          objeto.posicion.dy + distancia * sin(angulo),
        ),
      );
    }
    final pintura = Paint()..color = objeto.color;
    final path = Path()..addPolygon(puntos, true);
    canvas.drawPath(path, pintura);
  }

  @override
  bool shouldRepaint(covariant _EspacioPainter oldDelegate) {
    return oldDelegate.objetos != objetos;
  }
}

class _ObjetoEspacial {
  _ObjetoEspacial({
    required this.tipo,
    required this.posicion,
    required this.color,
    required this.tamano,
  });

  final _TipoObjeto tipo;
  final Offset posicion;
  final Color color;
  final double tamano;
}

enum _TipoObjeto { estrella, planeta, asteroide }

enum _Emocion { feliz, calmado, triste, asustado, enfadado }

class _EstiloEmocional {
  const _EstiloEmocional({
    required this.nombre,
    required this.icono,
    required this.colorPrimario,
    required this.colores,
    required this.tamanos,
    required this.pasoArrastre,
  });

  final String nombre;
  final String icono;
  final Color colorPrimario;
  final Map<_TipoObjeto, Color> colores;
  final Map<_TipoObjeto, double> tamanos;
  final double pasoArrastre;
}

const Map<_TipoObjeto, String> _nombresObjeto = {
  _TipoObjeto.estrella: 'Estrella',
  _TipoObjeto.planeta: 'Planeta',
  _TipoObjeto.asteroide: 'Asteroide',
};

final Map<_Emocion, _EstiloEmocional> _emociones = {
  _Emocion.feliz: _EstiloEmocional(
    nombre: 'Feliz',
    icono: '😀',
    colorPrimario: const Color(0xFFF7A63B),
    colores: {
      _TipoObjeto.estrella: const Color(0xFFFFFAD2),
      _TipoObjeto.planeta: const Color(0xFFFFB5C2),
      _TipoObjeto.asteroide: const Color(0xFFFFD18E),
    },
    tamanos: {
      _TipoObjeto.estrella: 16,
      _TipoObjeto.planeta: 32,
      _TipoObjeto.asteroide: 20,
    },
    pasoArrastre: 20,
  ),
  _Emocion.calmado: _EstiloEmocional(
    nombre: 'Calmado',
    icono: '🙂',
    colorPrimario: const Color(0xFF64C0C8),
    colores: {
      _TipoObjeto.estrella: const Color(0xFFE0FFF4),
      _TipoObjeto.planeta: const Color(0xFF7ED4B2),
      _TipoObjeto.asteroide: const Color(0xFFB8D5DC),
    },
    tamanos: {
      _TipoObjeto.estrella: 14,
      _TipoObjeto.planeta: 28,
      _TipoObjeto.asteroide: 18,
    },
    pasoArrastre: 24,
  ),
  _Emocion.triste: _EstiloEmocional(
    nombre: 'Triste',
    icono: '😢',
    colorPrimario: const Color(0xFF7A84FF),
    colores: {
      _TipoObjeto.estrella: const Color(0xFFD7E0FF),
      _TipoObjeto.planeta: const Color(0xFFB19CD9),
      _TipoObjeto.asteroide: const Color(0xFFA5B1C8),
    },
    tamanos: {
      _TipoObjeto.estrella: 12,
      _TipoObjeto.planeta: 26,
      _TipoObjeto.asteroide: 16,
    },
    pasoArrastre: 22,
  ),
  _Emocion.asustado: _EstiloEmocional(
    nombre: 'Asustado',
    icono: '😨',
    colorPrimario: const Color(0xFFB07CD3),
    colores: {
      _TipoObjeto.estrella: const Color(0xFFFBE7FF),
      _TipoObjeto.planeta: const Color(0xFFE0B7FF),
      _TipoObjeto.asteroide: const Color(0xFFC08AC8),
    },
    tamanos: {
      _TipoObjeto.estrella: 13,
      _TipoObjeto.planeta: 24,
      _TipoObjeto.asteroide: 18,
    },
    pasoArrastre: 18,
  ),
  _Emocion.enfadado: _EstiloEmocional(
    nombre: 'Enfadado',
    icono: '😡',
    colorPrimario: const Color(0xFFE56363),
    colores: {
      _TipoObjeto.estrella: const Color(0xFFFFEEE3),
      _TipoObjeto.planeta: const Color(0xFFFF9F9F),
      _TipoObjeto.asteroide: const Color(0xFFE78282),
    },
    tamanos: {
      _TipoObjeto.estrella: 16,
      _TipoObjeto.planeta: 30,
      _TipoObjeto.asteroide: 20,
    },
    pasoArrastre: 16,
  ),
};
