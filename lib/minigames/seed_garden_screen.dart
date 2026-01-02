import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/garden_plant.dart';
import '../services/experience_flags_service.dart';
import '../services/garden_storage_service.dart';
import '../services/session_log_service.dart';

class SeedGardenScreen extends StatefulWidget {
  const SeedGardenScreen({super.key});

  @override
  State<SeedGardenScreen> createState() => _SeedGardenScreenState();
}

class _SeedGardenScreenState extends State<SeedGardenScreen>
    with SingleTickerProviderStateMixin {
  final List<_Tree> _trees = [];
  final List<_Flower> _flowers = [];
  final Random _random = Random();
  final GlobalKey _gardenKey = GlobalKey();
  static const List<String> _calmTreeTypes = ['Green', 'Blue', 'Yellow', 'Red', 'White'];
  final GardenStorageService _gardenStorage = GardenStorageService();
  final ExperienceFlagsService _flags = ExperienceFlagsService.instance;
  final SessionLogService _sessionLog = SessionLogService.instance;
  _VegetationMode _mode = _VegetationMode.tree;
  _WeatherType _weather = _WeatherType.sunny;
  late _GardenMap _gardenMap;
  late final AnimationController _animalController;
  final List<GardenPlant> _pendingPlants = [];

  Timer? _growthTimer;
  Timer? _saveDebounce;
  int _counter = 0;
  String _calmMessage = 'Toca en cualquier lugar para hacer crecer tu bosque tranquilo.';
  Size _gardenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _sessionLog.startGardenSession();
    _gardenMap = _generateMap();
    _animalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addListener(() {
        if (mounted) setState(() {});
      })
      ..repeat();
    _growthTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _updateGrowth();
    });
    _loadGarden();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTip();
    });
  }

  _GardenMap _generateMap() {
    final riverStart = 0.2 + _random.nextDouble() * 0.4;
    final riverWidth = 0.15 + _random.nextDouble() * 0.08;
    final riverCurve = _random.nextDouble() * 0.4 - 0.2;
    final stones = List.generate(
      5,
      (_) => _MapCircle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        radius: 12 + _random.nextDouble() * 14,
      ),
    );
    final bushes = List.generate(
      4,
      (_) => _MapCircle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        radius: 24 + _random.nextDouble() * 20,
      ),
    );
    return _GardenMap(
      riverStart: riverStart,
      riverWidth: riverWidth,
      riverCurve: riverCurve,
      stones: stones,
      bushes: bushes,
      houses: _generateHouses(riverStart, riverWidth),
      animals: _generateAnimals(riverStart, riverWidth),
    );
  }

  List<_MapHouse> _generateHouses(double riverStart, double riverWidth) {
    final houses = <_MapHouse>[];
    final margin = 0.08;
    var attempts = 0;
    while (houses.length < 3 && attempts < 20) {
      final dx = _random.nextDouble();
      final dy = 0.65 + _random.nextDouble() * 0.25;
      if (dx > riverStart - margin && dx < riverStart + riverWidth + margin) {
        attempts++;
        continue;
      }
      houses.add(
        _MapHouse(
          position: Offset(dx, dy),
          scale: 0.8 + _random.nextDouble() * 0.5,
          bodyColor: Color.lerp(
            const Color(0xFFF8DCC1),
            const Color(0xFFEFC3A4),
            _random.nextDouble(),
          )!,
          roofColor: Color.lerp(
            const Color(0xFFDA8F7A),
            const Color(0xFFB46868),
            _random.nextDouble(),
          )!,
          doorColor: const Color(0xFF8D6E63),
        ),
      );
      attempts++;
    }
    return houses;
  }

  List<_MapAnimal> _generateAnimals(double riverStart, double riverWidth) {
    final animals = <_MapAnimal>[];
    const total = 4;
    for (var i = 0; i < total; i++) {
      final isBird = _random.nextBool();
      double dx;
      var tries = 0;
      do {
        dx = _random.nextDouble();
        tries++;
      } while (
          !isBird &&
              dx > riverStart - 0.05 &&
              dx < riverStart + riverWidth + 0.05 &&
              tries < 6);
      final dy = isBird
          ? 0.2 + _random.nextDouble() * 0.4
          : 0.6 + _random.nextDouble() * 0.25;
      animals.add(
        _MapAnimal(
          position: Offset(dx, dy),
          type: isBird ? _AnimalType.bird : _AnimalType.bunny,
          amplitude: isBird ? 0.015 + _random.nextDouble() * 0.015 : 0.008,
          horizontal: isBird,
          phaseOffset: _random.nextDouble() * pi * 2,
        ),
      );
    }
    return animals;
  }

  Future<void> _loadGarden() async {
    final saved = await _gardenStorage.loadGarden();
    if (!mounted) return;
    _pendingPlants
      ..clear()
      ..addAll(saved);
    _restoreGardenFromPlants();
  }

  void _updateGardenSize(Size newSize) {
    if (newSize == Size.zero || newSize == _gardenSize) {
      return;
    }
    _gardenSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreGardenFromPlants();
    });
  }

  void _restoreGardenFromPlants() {
    if (_pendingPlants.isEmpty || _gardenSize == Size.zero) {
      return;
    }
    final restoredTrees = _pendingPlants.map(_treeFromPlant).toList();
    setState(() {
      _trees
        ..clear()
        ..addAll(restoredTrees);
      _refreshCalmMessage();
    });
    _pendingPlants.clear();
  }

  void _updateGrowth() {
    if (_trees.isEmpty) return;
    var updated = false;
    setState(() {
      for (final tree in _trees) {
        if (tree.growth >= 1) continue;
        tree.growth = (tree.growth + 0.03 + _random.nextDouble() * 0.02)
            .clamp(0.0, 1.0);
        if (!tree.hasMatured && tree.growth >= 2 / 3) {
          tree.hasMatured = true;
          _sessionLog.recordTreeMatured();
        }
        updated = true;
      }
      if (updated) {
        _refreshCalmMessage();
      }
    });
    if (updated) {
      _scheduleSave();
    }
  }

  void _handleTap(TapDownDetails details) {
    final position = _calculateTapPosition(details);
    switch (_mode) {
      case _VegetationMode.tree:
        _createTree(position);
        break;
      case _VegetationMode.flower:
        _createFlower(position);
        break;
    }
  }

  Offset _calculateTapPosition(TapDownDetails details) {
    final renderBox =
        _gardenKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    final localPosition =
        renderBox?.globalToLocal(details.globalPosition) ?? details.localPosition;

    final dx = size == null
        ? localPosition.dx
        : localPosition.dx.clamp(45.0, max(45.0, size.width - 45.0)).toDouble();
    final dy = size == null
        ? localPosition.dy
        : localPosition.dy
            .clamp(130.0, max(130.0, size.height - 10.0))
            .toDouble();
    return Offset(dx, dy);
  }

  void _createTree(Offset position) {
    final treeType = _calmTreeTypes[_random.nextInt(_calmTreeTypes.length)];
    final style = _TreeStyle.forType(treeType);

    setState(() {
      _trees.add(
        _Tree(
          id: 'tree_${_counter++}',
          position: position,
          colorType: treeType,
          leafColor: style.leafColor,
          seedColor: style.seedColor,
          accentColor: style.accentColor,
          growth: 0,
          hasMatured: false,
        ),
      );
      _refreshCalmMessage();
    });
    _sessionLog.recordTreePlanted();
    _scheduleSave();
  }

  void _createFlower(Offset position) {
    const colors = [
      Color(0xFFFFC1C1),
      Color(0xFFFFE0AC),
      Color(0xFFB5EAD7),
      Color(0xFFD4C1EC),
      Color(0xFFAED9FF),
      Color(0xFFF8CCE3),
    ];
    setState(() {
      _flowers.add(
        _Flower(
          id: 'flower_${_counter++}',
          position: position,
          color: colors[_random.nextInt(colors.length)],
        ),
      );
      _refreshCalmMessage();
    });
    _sessionLog.recordFlowerPlanted();
  }

  void _refreshCalmMessage() {
    if (_trees.isEmpty) {
      _calmMessage = 'Toca en cualquier lugar para hacer crecer tu bosque tranquilo.';
      return;
    }
    final counts = _stageCounts();
    final seeds = counts['seeds']!;
    final sprouts = counts['sprouts']!;
    final grown = counts['grown']!;
    final flowers = _flowers.length;

    final parts = <String>[];
    if (grown > 0) {
      parts.add(
          '$grown árbol${grown == 1 ? '' : 'es'} tranquil${grown == 1 ? 'o' : 'os'} cuidando el jardín');
    }
    if (sprouts > 0) {
      parts.add('$sprouts brote${sprouts == 1 ? '' : 's'} estirándose con calma');
    }
    if (seeds > 0) {
      parts.add('$seeds semilla${seeds == 1 ? '' : 's'} descansando en la tierra');
    }
    var message = parts.join(', ');
    if (flowers > 0) {
      final florTexto = '$flowers flor${flowers == 1 ? '' : 'es'} sonriendo cerca';
      message = message.isEmpty ? florTexto : '$message. $florTexto';
    }
    _calmMessage = message.isEmpty
        ? 'Tu jardín está en silencio y espera nueva vida.'
        : '$message.';
  }

  Map<String, int> _stageCounts() {
    final counts = {'seeds': 0, 'sprouts': 0, 'grown': 0};
    for (final tree in _trees) {
      if (tree.growth < 1 / 3) {
        counts['seeds'] = counts['seeds']! + 1;
      } else if (tree.growth < 2 / 3) {
        counts['sprouts'] = counts['sprouts']! + 1;
      } else {
        counts['grown'] = counts['grown']! + 1;
      }
    }
    return counts;
  }

  GardenPlant _plantFromTree(_Tree tree) {
    final relative = _relativeFromAbsolute(tree.position);
    final stage = (tree.growth * GardenPlant.maxStage)
        .round()
        .clamp(0, GardenPlant.maxStage) as int;
    return GardenPlant(
      id: tree.id,
      emotion: _emotionForTreeType(tree.colorType),
      position: relative,
      stage: stage,
      progress: tree.growth,
      lastCare: DateTime.now(),
    );
  }

  _Tree _treeFromPlant(GardenPlant plant) {
    final type = _treeTypeForEmotion(plant.emotion);
    final style = _TreeStyle.forType(type);
    final position = _clampToGarden(
      _absoluteFromRelative(plant.position),
    );
    final growth = plant.progress.clamp(0.0, 1.0);
    return _Tree(
      id: plant.id,
      position: position,
      colorType: type,
      leafColor: style.leafColor,
      seedColor: style.seedColor,
      accentColor: style.accentColor,
      growth: growth,
      hasMatured: growth >= 2 / 3,
    );
  }

  Offset _relativeFromAbsolute(Offset absolute) {
    if (_gardenSize == Size.zero) {
      return const Offset(0.5, 0.7);
    }
    final dx = (absolute.dx / _gardenSize.width).clamp(0.0, 1.0);
    final dy = (absolute.dy / _gardenSize.height).clamp(0.0, 1.0);
    return Offset(dx, dy);
  }

  Offset _absoluteFromRelative(Offset relative) {
    if (_gardenSize == Size.zero) {
      return Offset(relative.dx * 300, relative.dy * 300);
    }
    return Offset(
      relative.dx * _gardenSize.width,
      relative.dy * _gardenSize.height,
    );
  }

  Offset _clampToGarden(Offset position) {
    if (_gardenSize == Size.zero) return position;
    final dx = position.dx.clamp(45.0, max(45.0, _gardenSize.width - 45.0));
    final dy =
        position.dy.clamp(130.0, max(130.0, _gardenSize.height - 10.0));
    return Offset(dx.toDouble(), dy.toDouble());
  }

  SeedEmotion _emotionForTreeType(String type) {
    switch (type) {
      case 'Yellow':
        return SeedEmotion.happy;
      case 'Blue':
        return SeedEmotion.sad;
      case 'Red':
        return SeedEmotion.brave;
      case 'White':
        return SeedEmotion.kind;
      case 'Green':
      default:
        return SeedEmotion.calm;
    }
  }

  String _treeTypeForEmotion(SeedEmotion emotion) {
    switch (emotion) {
      case SeedEmotion.happy:
        return 'Yellow';
      case SeedEmotion.sad:
        return 'Blue';
      case SeedEmotion.brave:
        return 'Red';
      case SeedEmotion.kind:
        return 'White';
      case SeedEmotion.calm:
      default:
        return 'Green';
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () {
      unawaited(_persistGarden());
    });
  }

  Future<void> _persistGarden() async {
    if (_gardenSize == Size.zero) return;
    final plants = _trees.map(_plantFromTree).toList();
    await _gardenStorage.saveGarden(plants);
  }

  @override
  void dispose() {
    _growthTimer?.cancel();
    _saveDebounce?.cancel();
    unawaited(_persistGarden());
    _animalController.dispose();
    unawaited(_sessionLog.endGardenSession());
    super.dispose();
  }

  Future<void> _maybeShowTip() async {
    final shown = await _flags.wasShown('garden_tip');
    if (shown || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jardín de Semillas'),
        content: const Text(
          'Planta semillas y obsérvalas crecer poco a poco. Respira y cuida tu bosque con paciencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plantar'),
          ),
        ],
      ),
    );
    await _flags.markShown('garden_tip');
  }

  @override
  Widget build(BuildContext context) {
    final stageCounts = _stageCounts();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jardín de Semillas'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _ModeSelector(
            mode: _mode,
            onModeChanged: (mode) {
              setState(() => _mode = mode);
            },
          ),
          _WeatherSelector(
            weather: _weather,
            onWeatherChanged: (weather) {
              setState(() => _weather = weather);
            },
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _handleTap,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _updateGardenSize(Size(constraints.maxWidth, constraints.maxHeight));
                  return SizedBox(
                    key: _gardenKey,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/garden_bg.png'),
                                repeat: ImageRepeat.repeat,
                                opacity: 0.2,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GardenPainter(
                              map: _gardenMap,
                              animalPhase: _animalController.value * 2 * pi,
                              weather: _weather,
                            ),
                          ),
                        ),
                        ..._trees.map((tree) {
                          return Positioned(
                            left: tree.position.dx - 45,
                            top: tree.position.dy - 130,
                            child: SizedBox(
                              width: 90,
                              height: 140,
                              child: _TreeGraphic(tree: tree),
                            ),
                          );
                        }).toList(),
                        ..._flowers.map((flower) {
                          return Positioned(
                            left: flower.position.dx - 10,
                            top: flower.position.dy - 10,
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(flower.id),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _FlowerDot(color: flower.color),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _CalmPanel(
            message: _calmMessage,
            seeds: stageCounts['seeds']!,
            sprouts: stageCounts['sprouts']!,
            grown: stageCounts['grown']!,
            flowers: _flowers.length,
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.onModeChanged,
  });

  final _VegetationMode mode;
  final ValueChanged<_VegetationMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F7FB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué te gustaría plantar?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _buildChip('Árboles', _VegetationMode.tree),
              _buildChip('Flores', _VegetationMode.flower),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, _VegetationMode value) {
    final isSelected = value == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF8FB3FF),
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4A6FA5),
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onModeChanged(value),
    );
  }
}

class _WeatherSelector extends StatelessWidget {
  const _WeatherSelector({
    required this.weather,
    required this.onWeatherChanged,
  });

  final _WeatherType weather;
  final ValueChanged<_WeatherType> onWeatherChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF1FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige el clima',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _buildChip('Soleado ☀️', _WeatherType.sunny),
              _buildChip('Nublado ☁️', _WeatherType.cloudy),
              _buildChip('Lluvioso 🌧️', _WeatherType.rainy),
              _buildChip('Nevado ❄️', _WeatherType.snowy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, _WeatherType value) {
    final isSelected = value == weather;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFAFE1FF),
      backgroundColor: const Color(0xFFE0F1FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4A6FA5),
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onWeatherChanged(value),
    );
  }
}

class _CalmPanel extends StatelessWidget {
  const _CalmPanel({
    required this.message,
    required this.seeds,
    required this.sprouts,
    required this.grown,
    required this.flowers,
  });

  final String message;
  final int seeds;
  final int sprouts;
  final int grown;
  final int flowers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF5),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _CalmStatChip(label: 'Semillas', value: seeds, emoji: '🫘'),
              _CalmStatChip(label: 'Brotes', value: sprouts, emoji: '🌱'),
              _CalmStatChip(label: 'Árboles', value: grown, emoji: '🌳'),
              _CalmStatChip(label: 'Flores', value: flowers, emoji: '🌼'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalmStatChip extends StatelessWidget {
  const _CalmStatChip({
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final int value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$emoji $label: $value',
        style: const TextStyle(
          color: Color(0xFF4A6FA5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _VegetationMode { tree, flower }
enum _WeatherType { sunny, cloudy, rainy, snowy }

class _MapHouse {
  _MapHouse({
    required this.position,
    required this.scale,
    required this.bodyColor,
    required this.roofColor,
    required this.doorColor,
  });

  final Offset position;
  final double scale;
  final Color bodyColor;
  final Color roofColor;
  final Color doorColor;
}

enum _AnimalType { bird, bunny }

class _MapAnimal {
  _MapAnimal({
    required this.position,
    required this.type,
    required this.amplitude,
    required this.horizontal,
    required this.phaseOffset,
  });

  final Offset position;
  final _AnimalType type;
  final double amplitude;
  final bool horizontal;
  final double phaseOffset;
}

class _TreeStyle {
  const _TreeStyle({
    required this.leafColor,
    required this.seedColor,
    required this.accentColor,
  });

  final Color leafColor;
  final Color seedColor;
  final Color accentColor;

  static _TreeStyle forType(String type) {
    switch (type) {
      case 'Red':
        return const _TreeStyle(
          leafColor: Color(0xFFF4A3A8),
          seedColor: Color(0xFFF7D3C6),
          accentColor: Color(0xFFF9C0C5),
        );
      case 'Blue':
        return const _TreeStyle(
          leafColor: Color(0xFFA7D0F5),
          seedColor: Color(0xFFD8ECFF),
          accentColor: Color(0xFF95BFE6),
        );
      case 'Yellow':
        return const _TreeStyle(
          leafColor: Color(0xFFF4DA8A),
          seedColor: Color(0xFFF8EDC6),
          accentColor: Color(0xFFFAE19E),
        );
      case 'White':
        return const _TreeStyle(
          leafColor: Color(0xFFEDEFF5),
          seedColor: Color(0xFFF7F8FC),
          accentColor: Color(0xFFD7DAE4),
        );
      case 'Green':
      default:
        return const _TreeStyle(
          leafColor: Color(0xFF8ECF9B),
          seedColor: Color(0xFFDCD7B5),
          accentColor: Color(0xFFB9E4C4),
        );
    }
  }
}

class _Tree {
  _Tree({
    required this.id,
    required this.position,
    required this.colorType,
    required this.leafColor,
    required this.seedColor,
    required this.accentColor,
    required this.growth,
    required this.hasMatured,
  });

  final String id;
  final Offset position;
  final String colorType;
  final Color leafColor;
  final Color seedColor;
  final Color accentColor;
  double growth;
  bool hasMatured;
}

class _Flower {
  _Flower({
    required this.id,
    required this.position,
    required this.color,
  });

  final String id;
  final Offset position;
  final Color color;
}

class _TreeGraphic extends StatelessWidget {
  const _TreeGraphic({required this.tree});

  final _Tree tree;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TreePainter(tree: tree),
    );
  }
}

class _FlowerDot extends StatelessWidget {
  const _FlowerDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _FlowerPainter(color),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final petalPaint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    for (var i = 0; i < 5; i++) {
      final angle = i * (2 * pi / 5);
      final offset = Offset(
        center.dx + cos(angle) * radius * 0.6,
        center.dy + sin(angle) * radius * 0.6,
      );
      canvas.drawCircle(offset, radius * 0.35, petalPaint);
    }
    canvas.drawCircle(
      center,
      radius * 0.45,
      Paint()..color = Colors.white.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({required this.tree});

  final _Tree tree;

  static const _trunkColor = Color(0xFF6D4C41);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = tree.growth;
    final stageLength = 1 / 3;
    final stage0 = (progress / stageLength).clamp(0.0, 1.0);
    final stage1 = ((progress - stageLength) / stageLength).clamp(0.0, 1.0);
    final stage2 = ((progress - stageLength * 2) / stageLength).clamp(0.0, 1.0);
    final baseY = size.height - 12;
    final centerX = size.width / 2;

    final moundPaint = Paint()..color = const Color(0xFF8B6F4E).withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY + 8),
        width: 50,
        height: 18,
      ),
      moundPaint,
    );

    if (stage0 > 0) {
      final seedRadius = 4 + 6 * stage0;
      final seedPaint = Paint()..color = tree.seedColor;
      canvas.drawCircle(
        Offset(centerX, baseY - 2 - stage0 * 3),
        seedRadius,
        seedPaint,
      );
    }

    if (stage1 > 0) {
      final sproutHeight = 28 + 12 * stage1;
      final sproutPaint = Paint()
        ..color = tree.accentColor.withOpacity(0.9)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(centerX, baseY - 4),
        Offset(centerX, baseY - 4 - sproutHeight),
        sproutPaint,
      );

      final leafPaint = Paint()..color = tree.leafColor;
      final leafCenterY = baseY - 6 - sproutHeight;
      final leafSize = 10 + 6 * stage1;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX - leafSize, leafCenterY),
          width: leafSize,
          height: leafSize * 0.6,
        ),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX + leafSize, leafCenterY),
          width: leafSize,
          height: leafSize * 0.6,
        ),
        leafPaint,
      );
    }

    if (stage2 > 0) {
      final trunkHeight = 40 + 30 * stage2;
      final trunkWidth = 10 + 6 * stage2;
      final trunkRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, baseY - trunkHeight / 2 - 6),
          width: trunkWidth,
          height: trunkHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(trunkRect, Paint()..color = _trunkColor);

      final canopyRadius = 24 + 18 * stage2;
      final canopyCenter = Offset(centerX, baseY - trunkHeight - 6);
      final canopyPaint = Paint()..color = tree.leafColor;
      canvas.drawCircle(canopyCenter, canopyRadius, canopyPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        canopyCenter.translate(-canopyRadius / 2, -canopyRadius / 3),
        canopyRadius * 0.45,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) {
    return oldDelegate.tree.growth != tree.growth ||
        oldDelegate.tree.leafColor != tree.leafColor ||
        oldDelegate.tree.accentColor != tree.accentColor;
  }
}

class _GardenMap {
  _GardenMap({
    required this.riverStart,
    required this.riverWidth,
    required this.riverCurve,
    required this.stones,
    required this.bushes,
    required this.houses,
    required this.animals,
  });

  final double riverStart;
  final double riverWidth;
  final double riverCurve;
  final List<_MapCircle> stones;
  final List<_MapCircle> bushes;
  final List<_MapHouse> houses;
  final List<_MapAnimal> animals;
}

class _MapCircle {
  _MapCircle({required this.position, required this.radius});

  final Offset position;
  final double radius;
}

class _GardenPainter extends CustomPainter {
  _GardenPainter({
    required this.map,
    required this.animalPhase,
    required this.weather,
  });

  final _GardenMap map;
  final double animalPhase;
  final _WeatherType weather;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    _drawRiver(canvas, size);
    _drawStones(canvas, size);
    _drawBushes(canvas, size);
    _drawHouses(canvas, size);
    _drawAnimals(canvas, size);
    _drawWeather(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    Gradient gradient;
    switch (weather) {
      case _WeatherType.sunny:
        gradient = const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFE4F6DE), Color(0xFFC8E6C9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case _WeatherType.cloudy:
        gradient = const LinearGradient(
          colors: [Color(0xFFE1E7EF), Color(0xFFDDE6F2), Color(0xFFC5D8E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case _WeatherType.rainy:
        gradient = const LinearGradient(
          colors: [Color(0xFFCFD8E7), Color(0xFFB8C7DA), Color(0xFFA4B6CD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case _WeatherType.snowy:
        gradient = const LinearGradient(
          colors: [Color(0xFFE8F4FF), Color(0xFFDDEBFE), Color(0xFFCFE0F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
    }

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    if (weather == _WeatherType.sunny) {
      final sunPaint = Paint()..color = const Color(0xFFFFE082).withOpacity(0.8);
      canvas.drawCircle(
        Offset(size.width - 80, 80),
        50,
        sunPaint,
      );
    } else if (weather == _WeatherType.cloudy) {
      _drawCloud(canvas, size, Offset(size.width * 0.3, size.height * 0.12));
      _drawCloud(canvas, size, Offset(size.width * 0.6, size.height * 0.18),
          scale: 1.2);
    }
  }

  void _drawRiver(Canvas canvas, Size size) {
    final startX = map.riverStart * size.width;
    final width = map.riverWidth * size.width;
    final curve = map.riverCurve * size.width;

    final path = Path()
      ..moveTo(startX, 0)
      ..quadraticBezierTo(
        startX - curve,
        size.height * 0.35,
        startX + width * 0.2,
        size.height * 0.6,
      )
      ..lineTo(startX + width + width * 0.2, size.height * 0.6)
      ..quadraticBezierTo(
        startX + width + curve,
        size.height * 0.85,
        startX + width,
        size.height,
      )
      ..lineTo(startX, size.height)
      ..close();

    final riverPaint = Paint()..color = const Color(0xFFAED9FF).withOpacity(0.85);
    canvas.drawPath(path, riverPaint);

    final ripple = Path()
      ..moveTo(startX + width * 0.2, size.height * 0.1)
      ..quadraticBezierTo(
        startX + width * 0.4 + curve / 2,
        size.height * 0.4,
        startX + width * 0.8,
        size.height * 0.9,
      );
    final ripplePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(ripple, ripplePaint);
  }

  void _drawStones(Canvas canvas, Size size) {
    final minSide = min(size.width, size.height);
    for (final stone in map.stones) {
      final center = Offset(
        stone.position.dx * size.width,
        stone.position.dy * size.height,
      );
      canvas.drawCircle(
        center,
        stone.radius * (minSide / 400),
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawBushes(Canvas canvas, Size size) {
    final minSide = min(size.width, size.height);
    for (final bush in map.bushes) {
      final center = Offset(
        bush.position.dx * size.width,
        bush.position.dy * size.height,
      );
      canvas.drawCircle(
        center,
        bush.radius * (minSide / 500),
        Paint()
          ..color = const Color(0xFFA5D6A7).withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawHouses(Canvas canvas, Size size) {
    final minSide = min(size.width, size.height);
    for (final house in map.houses) {
      final center = Offset(
        house.position.dx * size.width,
        house.position.dy * size.height,
      );
      final width = minSide * 0.18 * house.scale;
      final height = width * 0.7;
      final baseRect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );
      final paint = Paint()..color = house.bodyColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(baseRect, const Radius.circular(8)),
        paint,
      );

      final roofPath = Path()
        ..moveTo(baseRect.left - 4, baseRect.top)
        ..lineTo(baseRect.right + 4, baseRect.top)
        ..lineTo(baseRect.center.dx, baseRect.top - height * 0.6)
        ..close();
      canvas.drawPath(roofPath, Paint()..color = house.roofColor);

      final doorWidth = width * 0.2;
      final doorHeight = height * 0.5;
      final doorRect = Rect.fromCenter(
        center: Offset(baseRect.center.dx, baseRect.bottom - doorHeight / 2),
        width: doorWidth,
        height: doorHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(doorRect, const Radius.circular(4)),
        Paint()..color = house.doorColor,
      );
    }
  }

  void _drawAnimals(Canvas canvas, Size size) {
    final minSide = min(size.width, size.height);
    for (final animal in map.animals) {
      final wave =
          sin(animalPhase + animal.phaseOffset) * animal.amplitude;
      final center = Offset(
        animal.position.dx * size.width +
            (animal.horizontal ? wave * size.width : 0),
        animal.position.dy * size.height +
            (!animal.horizontal ? wave * size.height : 0),
      );
      final scale = minSide * (animal.type == _AnimalType.bird ? 0.035 : 0.05);
      switch (animal.type) {
        case _AnimalType.bird:
          _paintBird(canvas, center, scale);
          break;
        case _AnimalType.bunny:
          _paintBunny(canvas, center, scale);
          break;
      }
    }
  }

  void _drawWeather(Canvas canvas, Size size) {
    switch (weather) {
      case _WeatherType.sunny:
      case _WeatherType.cloudy:
        break;
      case _WeatherType.rainy:
        _drawRain(canvas, size);
        break;
      case _WeatherType.snowy:
        _drawSnow(canvas, size);
        break;
    }
  }

  void _drawCloud(Canvas canvas, Size size, Offset center,
      {double scale = 1}) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);
    final baseWidth = 120 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: baseWidth, height: 40 * scale),
      cloudPaint,
    );
    canvas.drawCircle(
      center.translate(-baseWidth * 0.3, -20 * scale),
      30 * scale,
      cloudPaint,
    );
    canvas.drawCircle(
      center.translate(baseWidth * 0.2, -25 * scale),
      35 * scale,
      cloudPaint,
    );
  }

  void _drawRain(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..color = const Color(0xFF6CA9D8).withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 80; i++) {
      final dx = _randomOffset(i, size.width);
      final dy = _randomOffset(i * 2, size.height);
      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx - 5, dy + 10),
        dropPaint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final snowPaint = Paint()..color = Colors.white.withOpacity(0.7);
    for (var i = 0; i < 60; i++) {
      final dx = _randomOffset(i, size.width);
      final dy = _randomOffset(i * 3, size.height);
      canvas.drawCircle(
        Offset(dx, dy),
        2.5,
        snowPaint,
      );
    }
  }

  double _randomOffset(int seed, double limit) {
    final random = Random(seed);
    return random.nextDouble() * limit;
  }

  void _paintBird(Canvas canvas, Offset center, double size) {
    final bodyPaint = Paint()..color = const Color(0xFFB5D8F2);
    final wingPaint = Paint()..color = const Color(0xFF8AB9DE);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size * 1.4,
        height: size,
      ),
      bodyPaint,
    );
    final wingCenter = center.translate(size * 0.1, 0);
    canvas.drawOval(
      Rect.fromCenter(
        center: wingCenter,
        width: size * 0.9,
        height: size * 0.8,
      ),
      wingPaint,
    );
    final beakPaint = Paint()..color = const Color(0xFFF8D08F);
    final beakPath = Path()
      ..moveTo(center.dx + size * 0.7, center.dy)
      ..lineTo(center.dx + size * 1.0, center.dy - size * 0.15)
      ..lineTo(center.dx + size * 1.0, center.dy + size * 0.15)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    canvas.drawCircle(
      Offset(center.dx - size * 0.3, center.dy - size * 0.15),
      size * 0.08,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(center.dx - size * 0.3, center.dy - size * 0.15),
      size * 0.05,
      Paint()..color = const Color(0xFF4A6FA5),
    );
  }

  void _paintBunny(Canvas canvas, Offset center, double size) {
    final bodyPaint = Paint()..color = const Color(0xFFEFE7F3);
    final earPaint = Paint()..color = const Color(0xFFE3D3EA);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, size * 0.1),
        width: size * 0.9,
        height: size * 1.2,
      ),
      Radius.circular(size * 0.4),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    final headCenter = center.translate(0, -size * 0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter,
        width: size * 0.9,
        height: size * 0.8,
      ),
      bodyPaint,
    );

    final earHeight = size * 0.9;
    for (final offset in [-size * 0.25, size * 0.25]) {
      final earRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: headCenter.translate(offset, -earHeight / 2),
          width: size * 0.3,
          height: earHeight,
        ),
        Radius.circular(size * 0.2),
      );
      canvas.drawRRect(earRect, earPaint);
    }

    canvas.drawCircle(
      headCenter.translate(-size * 0.2, -size * 0.05),
      size * 0.08,
      Paint()..color = const Color(0xFF4A6FA5),
    );
    canvas.drawCircle(
      headCenter.translate(size * 0.2, -size * 0.05),
      size * 0.08,
      Paint()..color = const Color(0xFF4A6FA5),
    );

    final nosePath = Path()
      ..moveTo(headCenter.dx, headCenter.dy)
      ..lineTo(headCenter.dx - size * 0.08, headCenter.dy + size * 0.08)
      ..lineTo(headCenter.dx + size * 0.08, headCenter.dy + size * 0.08)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFB56576));
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.animalPhase != animalPhase ||
        oldDelegate.weather != weather;
  }
}
