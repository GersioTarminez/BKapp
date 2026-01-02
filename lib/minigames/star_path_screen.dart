import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/drawing_storage_service.dart';
import '../services/preferences_service.dart';

class StarPathScreen extends StatefulWidget {
  const StarPathScreen({super.key});

  @override
  State<StarPathScreen> createState() => _StarPathScreenState();
}

class _StarPathScreenState extends State<StarPathScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final DrawingStorageService _storage = DrawingStorageService.instance;
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  final ValueNotifier<int> _repaintSignal = ValueNotifier<int>(0);
  final ValueNotifier<int> _starCountNotifier = ValueNotifier<int>(0);

  final Random _random = Random();
  final List<_StarNode> _stars = [];
  final List<_AmbientStar> _ambientStars = [];
  Size? _ambientSize;

  _ExpressionMode? _mode;
  String? _promptWord;
  Color _currentColor = _palette.first;
  _BrushType _currentBrush = _BrushType.star;

  bool _isSaving = false;
  bool _glowPulse = false;
  Timer? _glowTimer;
  Offset? _lastDragPoint;

  final Stopwatch _sessionWatch = Stopwatch();
  DateTime? _firstStarAt;
  bool _savePressed = false;
  int _starsPlaced = 0;
  double _pathLength = 0;

  late final AnimationController _pulseController;

  static const List<Color> _palette = [
    Color(0xFFFFC6B5),
    Color(0xFFFFE29F),
    Color(0xFFE5FFB8),
    Color(0xFFA6F7D3),
    Color(0xFFB5DBFF),
    Color(0xFFD9C4FF),
  ];

  static const List<String> _wordPool = [
    'LUZ',
    'HOGAR',
    'CAMINO',
    'CALMA',
    'SONRISAS',
    'SUEÑO',
    'VALENTIA',
    'NUBE',
    'ABRAZO',
    'SUSURRO',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addListener(() {
        _repaintSignal.value++;
      });
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _repaintSignal.dispose();
    _starCountNotifier.dispose();
    _glowTimer?.cancel();
    if (_sessionWatch.isRunning) {
      _sessionWatch.stop();
    }
    super.dispose();
  }

  void _selectMode(_ExpressionMode mode) {
    setState(() {
      _mode = mode;
      _promptWord = mode == _ExpressionMode.word
          ? _wordPool[_random.nextInt(_wordPool.length)]
          : null;
      _resetSession();
    });
  }

  void _resetSession() {
    _stars
      ..clear();
    _sessionWatch.reset();
    _firstStarAt = null;
    _savePressed = false;
    _starsPlaced = 0;
    _pathLength = 0;
    _glowPulse = false;
    _lastDragPoint = null;
    _starCountNotifier.value = 0;
    _repaintSignal.value++;
  }

  void _ensureAmbientStars(Size size) {
    if (_ambientSize == size && _ambientStars.isNotEmpty) return;
    _ambientSize = size;
    _ambientStars
      ..clear();
    final total = (size.width * size.height / 8000).clamp(60, 140).toInt();
    for (var i = 0; i < total; i++) {
      _ambientStars.add(
        _AmbientStar(
          position: Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
          radius: 0.8 + _random.nextDouble() * 1.8,
          opacity: 0.08 + _random.nextDouble() * 0.15,
        ),
      );
    }
    _repaintSignal.value++;
  }

  void _handleTap(Offset position) {
    _addStar(position);
  }

  void _handlePanStart(Offset position) {
    _lastDragPoint = position;
    _addStar(position);
  }

  void _handlePanUpdate(Offset position) {
    final spacing = _spacingForBrush(_currentBrush);
    if (_lastDragPoint == null ||
        (position - _lastDragPoint!).distance > spacing) {
      _lastDragPoint = position;
      _addStar(position);
    }
  }

  void _handlePanEnd() {
    _lastDragPoint = null;
  }

  void _addStar(Offset position) {
    if (_mode == null) return;
    if (_firstStarAt == null) {
      _firstStarAt = DateTime.now();
      _sessionWatch.start();
    }
    final radius = _radiusForBrush(_currentBrush);
    final star = _StarNode(
      position: position,
      color: _currentColor,
      radius: radius,
      createdAt: DateTime.now(),
      brush: _currentBrush,
      rotation: _random.nextDouble() * 2 * pi,
      jitter: _currentBrush == _BrushType.asteroid
          ? List<double>.generate(6, (_) => 0.8 + _random.nextDouble() * 0.4)
          : null,
    );
    if (_stars.isNotEmpty) {
      _pathLength +=
          (position - _stars.last.position).distance;
    }
    _stars.add(star);
    _starsPlaced++;
    _starCountNotifier.value = _stars.length;
    if (_starsPlaced >= 6 && !_glowPulse) {
      _glowPulse = true;
      _repaintSignal.value++;
      _glowTimer?.cancel();
      _glowTimer = Timer(const Duration(seconds: 4), () {
        _glowPulse = false;
        _repaintSignal.value++;
      });
    }
    _repaintSignal.value++;
  }

  void _clearConstellation() {
    setState(() {
      _resetSession();
    });
  }

  Future<ui.Image?> _captureCanvasImage() async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    var attempts = 0;
    while (boundary.debugNeedsPaint && attempts < 5) {
      await Future.delayed(const Duration(milliseconds: 32));
      attempts++;
    }
    if (boundary.debugNeedsPaint) {
      return null;
    }
    try {
      return await boundary.toImage(pixelRatio: 3);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDrawing() async {
    if (_stars.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final ui.Image? image = await _captureCanvasImage();
      if (image == null) {
        throw StateError('Canvas not ready to be captured');
      }
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('No image data produced');
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      _savePressed = true;
      _sessionWatch.stop();
      final metrics = {
        'stars_placed_count': _starsPlaced,
        'average_distance_between_stars':
            _starsPlaced > 1 ? _pathLength / (_starsPlaced - 1) : 0.0,
        'path_length_total': _pathLength,
        'drawing_duration_seconds':
            _firstStarAt == null ? 0.0 : _sessionWatch.elapsedMilliseconds / 1000.0,
        'save_pressed': true,
        'prompt_word': _promptWord,
      };
      final userName = PreferencesService.instance.cachedUserName;
      await _storage.saveDrawing(
        sessionId: _sessionId,
        mode: _mode?.name ?? 'unknown',
        word: _promptWord,
        pngBytes: bytes,
        metrics: metrics,
        userName: userName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Constelación guardada.')),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      debugPrint('StarPath save failed: $error\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el dibujo.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camino de Estrellas'),
        backgroundColor: const Color(0xFF0F1A2B),
        foregroundColor: Colors.white,
        actions: [
          if (_mode != null)
            ValueListenableBuilder<int>(
              valueListenable: _starCountNotifier,
              builder: (context, count, _) {
                final disabled = count == 0 || _isSaving;
                return TextButton.icon(
                  onPressed: disabled ? null : _saveDrawing,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text(
                    'Guardar dibujo',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _mode == null ? _buildModeSelection() : _buildConstellationStudio(),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1A2B), Color(0xFF1C2B45)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Cómo quieres crear tu camino de estrellas?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      title: 'PALABRA',
                      subtitle: 'Construye una constelación inspirada en una palabra',
                      icon: Icons.auto_fix_high,
                      colors: const [Color(0xFF4F47E2), Color(0xFF89A7FF)],
                      onTap: () => _selectMode(_ExpressionMode.word),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ModeButton(
                      title: 'LIBRE',
                      subtitle: 'Solo crea, sin indicaciones',
                      icon: Icons.bubble_chart,
                      colors: const [Color(0xFF1E88E5), Color(0xFF5DE0E6)],
                      onTap: () => _selectMode(_ExpressionMode.free),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConstellationStudio() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050918), Color(0xFF101F44)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          if (_mode == _ExpressionMode.word && _promptWord != null)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Column(
                children: [
                  const Text(
                    'INTERPRETA ESTA PALABRA',
                    style: TextStyle(
                      color: Color(0xFFB1C9FF),
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _promptWord!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          _buildPaletteBar(),
          _buildBrushSelector(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ensureAmbientStars(size);
                });
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: const Color(0xFF020512),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) => _handleTap(details.localPosition),
                          onPanStart: (details) => _handlePanStart(details.localPosition),
                          onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
                          onPanEnd: (_) => _handlePanEnd(),
                          child: CustomPaint(
                            painter: _StarPathPainter(
                              stars: _stars,
                              ambient: _ambientStars,
                              pulse: _pulseController.value,
                              glowPulse: _glowPulse,
                              now: DateTime.now(),
                              repaint: _repaintSignal,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ValueListenableBuilder<int>(
              valueListenable: _starCountNotifier,
              builder: (context, count, _) {
                return TextButton.icon(
                  onPressed: count == 0 ? null : _clearConstellation,
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  label: const Text(
                    'Borrar constelación',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Colores estelares',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _palette.map((color) {
                  final isSelected = color == _currentColor;
                  return GestureDetector(
                    onTap: () => setState(() => _currentColor = color),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            'Figuras',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 10,
              children: _BrushType.values.map((brush) {
                final selected = brush == _currentBrush;
                return ChoiceChip(
                  label: Icon(
                    _iconForBrush(brush),
                    color: selected ? Colors.white : Colors.white70,
                  ),
                  selected: selected,
                  selectedColor: Colors.white.withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  onSelected: (_) {
                    setState(() {
                      _currentBrush = brush;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _radiusForBrush(_BrushType type) {
    switch (type) {
      case _BrushType.star:
        return 6 + _random.nextDouble() * 3;
      case _BrushType.planet:
        return 7 + _random.nextDouble() * 2;
      case _BrushType.asteroid:
        return 5 + _random.nextDouble() * 2;
    }
  }

  double _spacingForBrush(_BrushType type) {
    switch (type) {
      case _BrushType.star:
        return 28;
      case _BrushType.planet:
        return 36;
      case _BrushType.asteroid:
        return 24;
    }
  }

  IconData _iconForBrush(_BrushType type) {
    switch (type) {
      case _BrushType.star:
        return Icons.star_rounded;
      case _BrushType.planet:
        return Icons.brightness_2;
      case _BrushType.asteroid:
        return Icons.blur_on;
    }
  }
}

enum _ExpressionMode { word, free }

enum _BrushType { star, planet, asteroid }

class _StarNode {
  _StarNode({
    required this.position,
    required this.color,
    required this.radius,
    required this.createdAt,
    required this.brush,
    required this.rotation,
    this.jitter,
  });

  final Offset position;
  final Color color;
  final double radius;
  final DateTime createdAt;
  final _BrushType brush;
  final double rotation;
  final List<double>? jitter;
}

class _AmbientStar {
  _AmbientStar({
    required this.position,
    required this.radius,
    required this.opacity,
  });

  final Offset position;
  final double radius;
  final double opacity;
}

class _StarPathPainter extends CustomPainter {
  _StarPathPainter({
    required this.stars,
    required this.ambient,
    required this.pulse,
    required this.glowPulse,
    required this.now,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_StarNode> stars;
  final List<_AmbientStar> ambient;
  final double pulse;
  final bool glowPulse;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    _drawAmbient(canvas);
    _drawStars(canvas);
  }

  void _drawAmbient(Canvas canvas) {
    final paint = Paint();
    for (final star in ambient) {
      paint
        ..color = Colors.white.withOpacity(star.opacity + (sin(pulse * 2 * pi) * 0.02))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(star.position, star.radius, paint);
    }
  }

  void _drawStars(Canvas canvas) {
    for (final star in stars) {
      final ageMs = now.difference(star.createdAt).inMilliseconds;
      final popProgress = (1 - (ageMs / 600)).clamp(0.0, 1.0);
      final glow = Paint()
        ..color = star.color.withOpacity(0.35 * popProgress + 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(star.position, star.radius + 6 * popProgress, glow);
      _drawBrushShape(canvas, star);
    }
  }

  void _drawBrushShape(Canvas canvas, _StarNode star) {
    final paint = Paint()
      ..color = star.color
      ..style = PaintingStyle.fill;
    switch (star.brush) {
      case _BrushType.star:
        final path = Path();
        const points = 5;
        final inner = star.radius * 0.45;
        for (var i = 0; i < points * 2; i++) {
          final angle = star.rotation + (i * pi / points);
          final radius = i.isEven ? star.radius : inner;
          final point = Offset(
            star.position.dx + radius * cos(angle),
            star.position.dy + radius * sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case _BrushType.planet:
        canvas.drawCircle(star.position, star.radius, paint);
        canvas.drawCircle(
          star.position,
          star.radius * 0.75,
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawOval(
          Rect.fromCircle(center: star.position, radius: star.radius * 1.4),
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        break;
      case _BrushType.asteroid:
        final jitter = star.jitter ?? List.filled(6, 1.0);
        final path = Path();
        const sides = 6;
        for (var i = 0; i < sides; i++) {
          final angle = star.rotation + (i / sides) * 2 * pi;
          final distance = star.radius * jitter[i % jitter.length];
          final point = Offset(
            star.position.dx + distance * cos(angle),
            star.position.dy + distance * sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StarPathPainter oldDelegate) => false;
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
