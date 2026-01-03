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
  String _calmMessage =
      'Toca en cualquier lugar para hacer crecer tu bosque tranquilo.';
  String _npcLine =
      'Hola, soy Mike el jardinero. ¿Listo para jugar con las plantas?';
  _NpcMoodOption? _activeMood;
  final List<_NpcMoodOption> _npcMoods = [
    _NpcMoodOption(
      label: '😀 Alegre',
      builder: (trees) {
        if (trees == 0) {
          return 'Parece que el jardín está un poco vacío, pero tu alegría llenará pronto este lugar.';
        }
        if (trees < 3) {
          return '¡Gracias por sonreír! Estos $trees arbolitos se contagian de tu ánimo.';
        }
        return 'Qué felicidad ver un jardín con $trees árboles brillando contigo.';
      },
    ),
    _NpcMoodOption(
      label: '😍 Muy feliz',
      builder: (trees) {
        if (trees == 0) {
          return 'Incluso sin árboles, tu entusiasmo me hace creer que será hermoso.';
        }
        return '¡Esto parece un jardín mágico con $trees árboles! Gracias por hacerlo tan especial.';
      },
    ),
    _NpcMoodOption(
      label: '😟 Tranquilo',
      builder: (trees) {
        if (trees == 0) {
          return 'Parece que el jardín está un poco vacío, pero podemos empezar juntos cuando quieras.';
        }
        return 'Respiremos hondo; cuidaremos los $trees árboles con paciencia y cariño.';
      },
    ),
    _NpcMoodOption(
      label: '😠 Molesto',
      builder: (trees) {
        if (trees == 0) {
          return 'Aunque esté vacío, ayudarme a plantar aliviará esa molestia paso a paso.';
        }
        return 'Transformemos ese enfado cuidando los $trees árboles con calma.';
      },
    ),
  ];
  final List<_SpecialAnimal> _specialAnimals = [];
  final List<_FriendPerson> _friendPeople = [];
  final Set<int> _unlockedThresholds = {};
  final List<int> _milestoneThresholds =
      const [0, 5, 10, 20, 30, 50, 60, 70, 80, 90, 100];
  final Map<int, String> _milestoneMessages = const {
    0: 'Mike te acompaña incluso cuando el jardín está vacío.',
    5: 'Las primeras raíces despiertan a nuevos amigos.',
    10: 'Diez árboles llenan el aire de historias tranquilas.',
    20: 'Veinte árboles hacen que el bosque cante en voz baja.',
    30: 'Treinta árboles crean un refugio muy especial.',
    50: 'Cincuenta árboles convierten este jardín en un bosque mágico.',
  };
  final Map<int, _AnimalSpec> _baseAnimalRewards = {
    0: _AnimalSpec('Conejito suave', _SpecialAnimalType.bunny, Color(0xFFF8D3DC)),
    5: _AnimalSpec('Ardilla brillante', _SpecialAnimalType.squirrel, Color(0xFFE0B985)),
    10: _AnimalSpec('Zorro amistoso', _SpecialAnimalType.fox, Color(0xFFFFA07A)),
    20: _AnimalSpec('Búho soñador', _SpecialAnimalType.owl, Color(0xFF8FA5C2)),
    30: _AnimalSpec('Pez rosa', _SpecialAnimalType.pinkFish, Color(0xFFE8B0FF)),
    50: _AnimalSpec('Mariposa lunar', _SpecialAnimalType.butterfly, Color(0xFFB3E5FC)),
  };
  final List<_AnimalSpec> _postFiftyAnimals = const [
    _AnimalSpec('Serpiente pequeña', _SpecialAnimalType.smallSnake, Color(0xFF81C784)),
    _AnimalSpec('Pez rosa', _SpecialAnimalType.pinkFish, Color(0xFFE8B0FF)),
    _AnimalSpec('Mariposa lunar', _SpecialAnimalType.butterfly, Color(0xFFB3E5FC)),
  ];
  final List<_PersonSpec> _personOptions = const [
    _PersonSpec('Peque aventurero', _PersonType.childExplorer),
    _PersonSpec('Amiga soñadora', _PersonType.dreamer),
  ];

  List<_AnimalSpec> get _manualAnimalOptions {
    final seen = <_SpecialAnimalType>{};
    final list = <_AnimalSpec>[];
    for (final spec in [
      ..._baseAnimalRewards.values,
      ..._postFiftyAnimals,
    ]) {
      if (seen.add(spec.type)) {
        list.add(spec);
      }
    }
    return list;
  }

  List<_FriendPaletteEntry> get _friendPaletteOptions {
    final entries = <_FriendPaletteEntry>[];
    for (final animal in _manualAnimalOptions) {
      entries.add(_FriendPaletteEntry(animalSpec: animal));
    }
    for (final person in _personOptions) {
      entries.add(_FriendPaletteEntry(personSpec: person));
    }
    return entries;
  }
  int _postFiftyIndex = 0;
  int _highestMilestone = 0;
  bool _creativeUnlocked = false;
  String? _toastMessage;
  Timer? _toastTimer;
  Size _gardenSize = Size.zero;
  _FriendPaletteEntry? _selectedFriendEntry;
  bool _isEraserMode = false;

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
    _checkMilestones(quietly: true);
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
    _checkMilestones(quietly: true);
    _maybeUnlockCreative(quietly: true);
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
    if (_isEraserMode) {
      _eraseAt(position);
      return;
    }
    if (_creativeUnlocked && _selectedFriendEntry != null) {
      _placeFriend(position);
      return;
    }
    switch (_mode) {
      case _VegetationMode.tree:
        _createTree(position);
        break;
      case _VegetationMode.flower:
        _createFlower(position);
        break;
    }
  }

  void _changeMode(_VegetationMode mode) {
    setState(() {
      _mode = mode;
      _selectedFriendEntry = null;
      _isEraserMode = false;
    });
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
    _checkMilestones();
    _sessionLog.recordTreePlanted();
    _scheduleSave();
    _maybeUnlockCreative();
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
    _maybeUnlockCreative();
  }

  void _placeFriend(Offset position) {
    final entry = _selectedFriendEntry;
    if (entry == null) return;
    final relative = _relativeFromAbsolute(position);
    setState(() {
      if (entry.isPerson) {
        _friendPeople.add(
          _FriendPerson(
            spec: entry.personSpec!,
            relativePosition: relative,
            phaseOffset: _random.nextDouble() * 2 * pi,
          ),
        );
      } else {
        _specialAnimals.add(
          _SpecialAnimal(
            spec: entry.animalSpec!,
            relativePosition: relative,
            threshold: _highestMilestone,
            isManual: true,
            phaseOffset: _random.nextDouble() * 2 * pi,
            amplitude: 6 + _random.nextDouble() * 4,
          ),
        );
      }
    });
  }

  void _eraseAt(Offset position) {
    double? bestDistance;
    VoidCallback? removeAction;

    Offset? _recordRemoval(double distance, VoidCallback action) {
      if (bestDistance == null || distance < bestDistance!) {
        bestDistance = distance;
        removeAction = action;
      }
      return null;
    }

    for (final tree in List<_Tree>.from(_trees)) {
      final distance = (tree.position - position).distance;
      if (distance < 70) {
        _recordRemoval(distance, () {
          _trees.remove(tree);
          _refreshCalmMessage();
          _scheduleSave();
        });
      }
    }

    for (final flower in List<_Flower>.from(_flowers)) {
      final distance = (flower.position - position).distance;
      if (distance < 50) {
        _recordRemoval(distance, () {
          _flowers.remove(flower);
          _refreshCalmMessage();
          _scheduleSave();
        });
      }
    }

    for (final friend in List<_SpecialAnimal>.from(_specialAnimals)) {
      final absolute = _absoluteFromRelative(friend.relativePosition);
      final distance = (absolute - position).distance;
      if (distance < 60) {
        _recordRemoval(distance, () {
          _specialAnimals.remove(friend);
        });
      }
    }

    for (final person in List<_FriendPerson>.from(_friendPeople)) {
      final absolute = _absoluteFromRelative(person.relativePosition);
      final distance = (absolute - position).distance;
      if (distance < 60) {
        _recordRemoval(distance, () {
          _friendPeople.remove(person);
        });
      }
    }

    if (removeAction != null) {
      setState(() {
        removeAction!.call();
      });
    }
  }

  Future<void> _confirmClearGarden() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar jardín'),
        content: const Text(
            'Se eliminarán árboles, flores y amigos del jardín. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    setState(() {
      _trees.clear();
      _flowers.clear();
      _specialAnimals.clear();
      _friendPeople.clear();
      _selectedFriendEntry = null;
      _isEraserMode = false;
      _unlockedThresholds
        ..clear();
      _highestMilestone = 0;
      _creativeUnlocked = false;
      _postFiftyIndex = 0;
      _refreshCalmMessage();
    });
    _scheduleSave();
  }

  void _openFriendPalette() {
    if (!_creativeUnlocked || !mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _FriendPaletteSheet(
            options: _friendPaletteOptions,
            selected: _selectedFriendEntry,
            onOptionSelected: (entry) {
              Navigator.pop(context);
              setState(() {
                _selectedFriendEntry = entry;
                _isEraserMode = false;
              });
            },
            onClearSelection: () {
              Navigator.pop(context);
              setState(() {
                _selectedFriendEntry = null;
              });
            },
          ),
        );
      },
    );
  }

  void _refreshCalmMessage() {
    if (_trees.isEmpty) {
      _calmMessage = 'Toca en cualquier lugar para hacer crecer tu bosque tranquilo.';
      _npcLine = _baselineNpcLine(0);
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
    if (_activeMood != null) {
      _npcLine = _activeMood!.messageForTrees(_trees.length);
    } else {
      _npcLine = _baselineNpcLine(_trees.length);
    }
  }

  double _plantScore() => _trees.length + (_flowers.length * 0.5);

  void _maybeUnlockCreative({bool quietly = false}) {
    if (_creativeUnlocked) return;
    if (_plantScore() < 50) return;
    setState(() {
      _creativeUnlocked = true;
    });
    if (!quietly) {
      _showToast(
        '¡Has llegado a 50 puntos de jardín! Ahora puedes elegir qué amigos y personas acompañan tu bosque.',
      );
    }
  }

  String _baselineNpcLine(int totalTrees) {
    if (totalTrees == 0) {
      return 'Parece que el jardín está un poco vacío, ¿sembramos la primera semilla?';
    }
    if (totalTrees < 3) {
      return 'Ya hay $totalTrees árbol${totalTrees == 1 ? '' : 'es'} saludando despacio.';
    }
    if (totalTrees < 6) {
      return 'El jardín se siente vivo con estos $totalTrees árboles felices.';
    }
    return 'Vaya bosque sereno el que estás levantando aquí.';
  }

  void _checkMilestones({bool quietly = false}) {
    final totalTrees = _trees.length;
    final newAnimals = <_SpecialAnimal>[];
    var unlockedSomething = false;
    for (final threshold in _milestoneThresholds) {
      if (totalTrees >= threshold &&
          !_unlockedThresholds.contains(threshold)) {
        _unlockedThresholds.add(threshold);
        unlockedSomething = true;
        final spec = _animalSpecForThreshold(threshold);
        if (spec != null) {
          newAnimals.add(
            _SpecialAnimal(
              spec: spec,
              relativePosition: _randomAnimalSpot(),
              threshold: threshold,
              phaseOffset: _random.nextDouble() * 2 * pi,
              amplitude: 5 + _random.nextDouble() * 4,
              isManual: false,
            ),
          );
        }
      }
    }

    final newHighest = _unlockedThresholds.isEmpty
        ? 0
        : _unlockedThresholds.reduce(max);
    if (!unlockedSomething && newHighest == _highestMilestone) {
      return;
    }
    setState(() {
      _specialAnimals.addAll(newAnimals);
      _highestMilestone = newHighest;
    });

    if (!quietly && newAnimals.isNotEmpty) {
      final unlocked = newAnimals.last;
      final baseMessage = _milestoneMessages[unlocked.threshold] ??
          'Has alcanzado $newHighest árboles.';
      _showToast(
        '$baseMessage ¡${unlocked.spec.displayName} ha llegado para quedarse!',
      );
    }
  }

  _AnimalSpec? _animalSpecForThreshold(int threshold) {
    if (_baseAnimalRewards.containsKey(threshold)) {
      return _baseAnimalRewards[threshold];
    }
    if (threshold >= 60 && threshold <= 100) {
      final spec = _postFiftyAnimals[
          _postFiftyIndex % _postFiftyAnimals.length];
      _postFiftyIndex++;
      return spec;
    }
    return null;
  }

  Offset _randomAnimalSpot() {
    final dx = 0.15 + _random.nextDouble() * 0.7;
    final dy = 0.45 + _random.nextDouble() * 0.4;
    return Offset(dx.clamp(0.05, 0.95), dy.clamp(0.35, 0.95));
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _toastMessage = null;
      });
    });
    setState(() {
      _toastMessage = message;
    });
  }

  void _handleMoodTap(_NpcMoodOption mood) {
    setState(() {
      for (final option in _npcMoods) {
        option.isActive = option == mood;
      }
      _activeMood = mood;
      _npcLine = mood.messageForTrees(_trees.length);
    });
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
    _toastTimer?.cancel();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jardín de Semillas'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                _ModeSelector(
                  mode: _mode,
                  onModeChanged: _changeMode,
                ),
                _WeatherSelector(
                  weather: _weather,
                  onWeatherChanged: (weather) {
                    setState(() => _weather = weather);
                  },
                ),
                _GardenToolsBar(
                  isEraserActive: _isEraserMode,
                  onToggleEraser: (value) {
                    setState(() {
                      _isEraserMode = value;
                      if (value) {
                        _selectedFriendEntry = null;
                      }
                    });
                  },
                  onClearGarden: _confirmClearGarden,
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _handleTap,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _updateGardenSize(
                            Size(constraints.maxWidth, constraints.maxHeight));
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
                                      image:
                                          AssetImage('assets/images/garden_bg.png'),
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
                              ..._buildSpecialAnimalWidgets(),
                              ..._buildFriendPersonWidgets(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: _CalmPanel(
                    message: _calmMessage,
                    companionLine: _npcLine,
                    moods: _npcMoods,
                    onMoodSelected: _handleMoodTap,
                    medalValue: _highestMilestone,
                    canManageFriends: _creativeUnlocked,
                    onManageFriends:
                        _creativeUnlocked ? _openFriendPalette : null,
                  ),
                ),
              ],
            ),
          ),
          if (_toastMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _ToastBanner(message: _toastMessage!),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecialAnimalWidgets() {
    if (_specialAnimals.isEmpty) return const <Widget>[];
    final wave = _animalController.value * 2 * pi;
    return _specialAnimals.map((animal) {
      final position = _gardenSize == Size.zero
          ? Offset(150, 200)
          : Offset(
              animal.relativePosition.dx * _gardenSize.width,
              animal.relativePosition.dy * _gardenSize.height,
            );
      final bob =
          sin(wave + animal.phaseOffset) * animal.amplitude;
      return Positioned(
        left: position.dx - 27,
        top: position.dy - 27,
        child: _FriendAnimalChip(
          spec: animal.spec,
          bob: bob,
        ),
      );
    }).toList();
  }

  List<Widget> _buildFriendPersonWidgets() {
    if (_friendPeople.isEmpty) return const <Widget>[];
    final wave = _animalController.value * 2 * pi;
    return _friendPeople.map((person) {
      final position = _gardenSize == Size.zero
          ? Offset(150, 220)
          : Offset(
              person.relativePosition.dx * _gardenSize.width,
              person.relativePosition.dy * _gardenSize.height,
            );
      final bob = sin(wave + person.phaseOffset) * 4;
      return Positioned(
        left: position.dx - 28,
        top: position.dy - 40,
        child: _FriendPersonWidget(
          spec: person.spec,
          bob: bob,
        ),
      );
    }).toList();
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

class _GardenToolsBar extends StatelessWidget {
  const _GardenToolsBar({
    required this.isEraserActive,
    required this.onToggleEraser,
    required this.onClearGarden,
  });

  final bool isEraserActive;
  final ValueChanged<bool> onToggleEraser;
  final VoidCallback onClearGarden;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FAFE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Borrador'),
            selected: isEraserActive,
            onSelected: onToggleEraser,
            selectedColor: const Color(0xFFFFD5D5),
            backgroundColor: const Color(0xFFF1F2FA),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onClearGarden,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }
}

class _CalmPanel extends StatelessWidget {
  const _CalmPanel({
    required this.message,
    required this.companionLine,
    required this.moods,
    required this.onMoodSelected,
    required this.medalValue,
    this.canManageFriends = false,
    this.onManageFriends,
  });

  final String message;
  final String companionLine;
  final List<_NpcMoodOption> moods;
  final void Function(_NpcMoodOption) onMoodSelected;
  final int medalValue;
  final bool canManageFriends;
  final VoidCallback? onManageFriends;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companionLine,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F7D95),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const _GardenerAvatar(),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: _MedalBadge(value: medalValue),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: moods.map((mood) {
            return ChoiceChip(
              label: Text(mood.label),
              selected: mood.isActive,
              onSelected: (_) => onMoodSelected(mood),
            );
          }).toList(),
        ),
        if (canManageFriends) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onManageFriends,
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: const Text('Amigos del jardín'),
            ),
          ),
        ],
      ],
    );
  }
}

class _GardenerAvatar extends StatelessWidget {
  const _GardenerAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 90,
      child: CustomPaint(
        painter: _GardenerPainter(),
      ),
    );
  }
}

class _GardenerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final facePaint = Paint()..color = const Color(0xFFFFE7D3);
    canvas.drawCircle(Offset(center, size.height * 0.35), size.width * 0.22, facePaint);

    final hatPaint = Paint()..color = const Color(0xFFB6864B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center, size.height * 0.18),
          width: size.width * 0.7,
          height: size.height * 0.13,
        ),
        const Radius.circular(10),
      ),
      hatPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center, size.height * 0.2),
        width: size.width * 0.9,
        height: size.height * 0.05,
      ),
      hatPaint,
    );

    final bodyPaint = Paint()..color = const Color(0xFF4A6FA5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.5,
          size.width * 0.5,
          size.height * 0.4,
        ),
        const Radius.circular(12),
      ),
      bodyPaint,
    );

    final pocketPaint = Paint()..color = const Color(0xFFE3ECFF);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center, size.height * 0.7),
        width: size.width * 0.3,
        height: size.height * 0.2,
      ),
      pocketPaint,
    );

    final eyePaint = Paint()..color = const Color(0xFF4A6FA5);
    canvas.drawCircle(Offset(center - 10, size.height * 0.34), 3, eyePaint);
    canvas.drawCircle(Offset(center + 10, size.height * 0.34), 3, eyePaint);
    final smile = Path()
      ..moveTo(center - 10, size.height * 0.4)
      ..quadraticBezierTo(
          center, size.height * 0.45, center + 10, size.height * 0.4);
    final smilePaint = Paint()
      ..color = const Color(0xFF4A6FA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(smile, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE29A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 16, color: Color(0xFFAA7A00)),
            const SizedBox(width: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A5B00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  const _ToastBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF4A6FA5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialAnimal {
  _SpecialAnimal({
    required this.spec,
    required this.relativePosition,
    required this.threshold,
    required this.phaseOffset,
    required this.amplitude,
    this.isManual = false,
  });

  final _AnimalSpec spec;
  final Offset relativePosition;
  final int threshold;
  final double phaseOffset;
  final double amplitude;
  final bool isManual;
}

class _FriendPerson {
  _FriendPerson({
    required this.spec,
    required this.relativePosition,
    required this.phaseOffset,
  });

  final _PersonSpec spec;
  final Offset relativePosition;
  final double phaseOffset;
}

class _AnimalSpec {
  const _AnimalSpec(this.displayName, this.type, this.color);

  final String displayName;
  final _SpecialAnimalType type;
  final Color color;
}

enum _SpecialAnimalType {
  bunny,
  squirrel,
  fox,
  owl,
  pinkFish,
  butterfly,
  smallSnake,
}

class _FriendAnimalChip extends StatelessWidget {
  const _FriendAnimalChip({required this.spec, required this.bob});

  final _AnimalSpec spec;
  final double bob;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, bob),
      child: SizedBox(
        width: 54,
        height: 54,
        child: CustomPaint(
          painter: _AnimalSpritePainter(spec.type),
        ),
      ),
    );
  }
}

class _AnimalSpritePainter extends CustomPainter {
  _AnimalSpritePainter(this.type);

  final _SpecialAnimalType type;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _SpecialAnimalType.bunny:
        _drawBunny(canvas, size);
        break;
      case _SpecialAnimalType.squirrel:
        _drawSquirrel(canvas, size);
        break;
      case _SpecialAnimalType.fox:
        _drawFox(canvas, size);
        break;
      case _SpecialAnimalType.owl:
        _drawOwl(canvas, size);
        break;
      case _SpecialAnimalType.pinkFish:
        _drawPinkFish(canvas, size);
        break;
      case _SpecialAnimalType.butterfly:
        _drawButterfly(canvas, size);
        break;
      case _SpecialAnimalType.smallSnake:
        _drawSmallSnake(canvas, size);
        break;
    }
  }

  void _drawBunny(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFFFF6FB);
    final ear = Paint()..color = const Color(0xFFF4D7E6);
    final center = size.center(Offset.zero);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 4), width: size.width * 0.8, height: size.height * 0.65),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(-8, -6), width: size.width * 0.25, height: size.height * 0.5),
      ear,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(8, -6), width: size.width * 0.25, height: size.height * 0.5),
      ear,
    );
    canvas.drawCircle(center.translate(-6, -2), 3, Paint()..color = Colors.black54);
    canvas.drawCircle(center.translate(6, -2), 3, Paint()..color = Colors.black54);
    final nose = Path()
      ..moveTo(center.dx, center.dy + 2)
      ..lineTo(center.dx - 3, center.dy + 6)
      ..lineTo(center.dx + 3, center.dy + 6)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFE07A8C));
  }

  void _drawSquirrel(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFF5C392);
    final tail = Paint()..color = const Color(0xFFF2A46F);
    final center = size.center(Offset.zero);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(5, -2), width: size.width * 0.7, height: size.height * 0.6),
      body,
    );
    canvas.drawCircle(center.translate(-10, 4), size.width * 0.35, tail);
    final headCenter = center.translate(6, -10);
    canvas.drawCircle(headCenter, size.width * 0.24, body);
    final eyePaint = Paint()..color = const Color(0xFF4B3C35);
    canvas.drawCircle(headCenter.translate(-6, -4), 3, eyePaint);
    canvas.drawCircle(headCenter.translate(6, -4), 3, eyePaint);
    final mouth = Path()
      ..moveTo(headCenter.dx - 4, headCenter.dy + 6)
      ..quadraticBezierTo(headCenter.dx, headCenter.dy + 10, headCenter.dx + 4, headCenter.dy + 6);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = const Color(0xFF7A4C32)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFox(Canvas canvas, Size size) {
    final orange = Paint()..color = const Color(0xFFFFB07C);
    final white = Paint()..color = Colors.white;
    final center = size.center(Offset.zero);
    final bodyRect = Rect.fromCenter(center: center.translate(0, 5), width: size.width * 0.7, height: size.height * 0.55);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(12)), orange);
    final leftEar = Path()
      ..moveTo(center.dx - 18, center.dy - 10)
      ..lineTo(center.dx - 4, center.dy - 36)
      ..lineTo(center.dx, center.dy - 8)
      ..close();
    canvas.drawPath(leftEar, orange);
    final rightEar = Path()
      ..moveTo(center.dx + 18, center.dy - 10)
      ..lineTo(center.dx + 4, center.dy - 36)
      ..lineTo(center.dx, center.dy - 8)
      ..close();
    canvas.drawPath(rightEar, orange);
    final headCenter = center.translate(0, -8);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: size.width * 0.65, height: size.height * 0.45), orange);
    final muzzle = Path()
      ..moveTo(center.dx - 12, center.dy + 4)
      ..lineTo(center.dx, center.dy + 14)
      ..lineTo(center.dx + 12, center.dy + 4)
      ..close();
    canvas.drawPath(muzzle, white);
    canvas.drawCircle(headCenter.translate(-10, -2), 4, Paint()..color = Colors.white);
    canvas.drawCircle(headCenter.translate(10, -2), 4, Paint()..color = Colors.white);
    canvas.drawCircle(headCenter.translate(-10, -2), 2, Paint()..color = Colors.black54);
    canvas.drawCircle(headCenter.translate(10, -2), 2, Paint()..color = Colors.black54);
    canvas.drawCircle(center.translate(0, 6), 2, Paint()..color = const Color(0xFF773E28));
  }

  void _drawOwl(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF9AB3D0);
    final wing = Paint()..color = const Color(0xFF7992B7);
    final center = size.center(Offset.zero);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.7, height: size.height * 0.8),
        const Radius.circular(18),
      ),
      body,
    );
    canvas.drawOval(Rect.fromCenter(center: center.translate(-6, 4), width: 26, height: 34), wing);
    canvas.drawOval(Rect.fromCenter(center: center.translate(6, 4), width: 26, height: 34), wing);
    canvas.drawCircle(center.translate(-8, -8), 6, Paint()..color = Colors.white);
    canvas.drawCircle(center.translate(8, -8), 6, Paint()..color = Colors.white);
    canvas.drawCircle(center.translate(-8, -8), 3, Paint()..color = Colors.black54);
    canvas.drawCircle(center.translate(8, -8), 3, Paint()..color = Colors.black54);
    final beak = Path()
      ..moveTo(center.dx, center.dy - 2)
      ..lineTo(center.dx - 4, center.dy + 4)
      ..lineTo(center.dx + 4, center.dy + 4)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFF6D36D));
  }

  void _drawPinkFish(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFFFB4D3);
    final fin = Paint()..color = const Color(0xFFFF8EC3);
    final center = size.center(Offset.zero);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.9,
        height: size.height * 0.45,
      ),
      body,
    );
    final tailPath = Path()
      ..moveTo(center.dx + size.width * 0.45, center.dy)
      ..quadraticBezierTo(
          center.dx + size.width * 0.62, center.dy - size.height * 0.2, center.dx + size.width * 0.7, center.dy)
      ..quadraticBezierTo(
          center.dx + size.width * 0.62, center.dy + size.height * 0.2, center.dx + size.width * 0.45, center.dy)
      ..close();
    canvas.drawPath(tailPath, fin);
    canvas.drawCircle(center.translate(-size.width * 0.25, -4), 4, Paint()..color = Colors.white);
    canvas.drawCircle(center.translate(-size.width * 0.25, -4), 2, Paint()..color = Colors.black54);
    canvas.drawCircle(
      center.translate(-size.width * 0.15, 4),
      2,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }

  void _drawButterfly(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = const Color(0xFF5B5B8F);
    final leftWing = Paint()..color = const Color(0xFFB9E0FF);
    final rightWing = Paint()..color = const Color(0xFF8CCCF9);
    final center = size.center(Offset.zero);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 8, height: size.height * 0.7),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(-12, 0), width: size.width * 0.6, height: size.height * 0.4),
      leftWing,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(12, 0), width: size.width * 0.6, height: size.height * 0.4),
      rightWing,
    );
  }

  void _drawSmallSnake(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF79D08A);
    final belly = Paint()..color = const Color(0xFFA7E5B6);
    final center = size.center(Offset.zero);
    final path = Path()
      ..moveTo(center.dx - size.width * 0.4, center.dy + size.height * 0.1)
      ..quadraticBezierTo(center.dx - 10, center.dy - 20, center.dx + 15, center.dy + 10)
      ..quadraticBezierTo(center.dx + 35, center.dy + 35, center.dx + size.width * 0.35, center.dy - 5);
    final stroke = Paint()
      ..color = body.color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
    final stripe = Paint()
      ..color = belly.color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stripe);
    final headCenter = Offset(center.dx + size.width * 0.35, center.dy - 10);
    canvas.drawCircle(headCenter, 9, body);
    canvas.drawCircle(headCenter.translate(-3, -1), 2, Paint()..color = Colors.white);
    canvas.drawCircle(headCenter.translate(3, -1), 2, Paint()..color = Colors.white);
    canvas.drawLine(
      headCenter.translate(6, 2),
      headCenter.translate(12, 6),
      Paint()
        ..color = Colors.pinkAccent
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }


  void _drawBeak(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  void _drawPolygon(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimalSpritePainter oldDelegate) =>
      oldDelegate.type != type;
}

class _FriendPaletteEntry {
  _FriendPaletteEntry({
    this.animalSpec,
    this.personSpec,
  }) : assert((animalSpec == null) != (personSpec == null)),
        id = animalSpec != null
            ? 'animal_${animalSpec!.type.name}'
            : 'person_${personSpec!.type.name}';

  final _AnimalSpec? animalSpec;
  final _PersonSpec? personSpec;
  final String id;

  bool get isPerson => personSpec != null;
  String get label => animalSpec?.displayName ?? personSpec!.displayName;
}

class _PersonSpec {
  const _PersonSpec(this.displayName, this.type);

  final String displayName;
  final _PersonType type;
}

enum _PersonType { childExplorer, dreamer }

class _FriendPaletteSheet extends StatelessWidget {
  const _FriendPaletteSheet({
    required this.options,
    required this.selected,
    required this.onOptionSelected,
    required this.onClearSelection,
  });

  final List<_FriendPaletteEntry> options;
  final _FriendPaletteEntry? selected;
  final ValueChanged<_FriendPaletteEntry?> onOptionSelected;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Color(0xFF4A6FA5)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Amigos del jardín',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FriendsGrid(
              options: options,
              selected: selected,
              onOptionSelected: onOptionSelected,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Sin selección'),
                ),
                const Spacer(),
                const Text(
                  'Toca un amigo y luego el jardín para colocarlo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F7D95),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsGrid extends StatelessWidget {
  const _FriendsGrid({
    required this.options,
    required this.selected,
    required this.onOptionSelected,
  });

  final List<_FriendPaletteEntry> options;
  final _FriendPaletteEntry? selected;
  final ValueChanged<_FriendPaletteEntry?> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_FriendPaletteEntry>>[];
    for (var i = 0; i < options.length; i += 3) {
      rows.add(
        options.sublist(i, i + 3 > options.length ? options.length : i + 3),
      );
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(3, (index) {
              if (index >= row.length) {
                return const Expanded(child: SizedBox());
              }
              final entry = row[index];
              final isSelected = entry.id == selected?.id;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: _FriendTile(
                    entry: entry,
                    selected: isSelected,
                    onTap: () => onOptionSelected(isSelected ? null : entry),
                  ),
                ),
              );
            }),
          ),
        );
      }).toList(),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _FriendPaletteEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF8FB3FF) : const Color(0xFFF0F4FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.isPerson ? Icons.emoji_people : Icons.pets,
                color: selected ? Colors.white : const Color(0xFF5F6F8F),
              ),
              const SizedBox(height: 6),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF4A5A7B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendPersonWidget extends StatelessWidget {
  const _FriendPersonWidget({required this.spec, required this.bob});

  final _PersonSpec spec;
  final double bob;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, bob),
      child: SizedBox(
        width: 56,
        height: 70,
        child: CustomPaint(
          painter: _PersonSpritePainter(spec.type),
        ),
      ),
    );
  }
}

class _PersonSpritePainter extends CustomPainter {
  _PersonSpritePainter(this.type);

  final _PersonType type;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _PersonType.childExplorer:
        _paintExplorer(canvas, size);
        break;
      case _PersonType.dreamer:
        _paintDreamer(canvas, size);
        break;
    }
  }

  void _paintExplorer(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF88C0A7);
    final head = Paint()..color = const Color(0xFFFFE2C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.35, size.width * 0.4, size.height * 0.5),
        const Radius.circular(12),
      ),
      body,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.18,
      head,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.5, 6),
      Paint()..color = const Color(0xFF4F6B8A),
    );
    _drawSimpleFace(
      canvas,
      center: Offset(size.width * 0.5, size.height * 0.25),
      eyeSpacing: 10,
      eyeColor: const Color(0xFF4D3A30),
      smileWidth: 12,
    );
  }

  void _paintDreamer(Canvas canvas, Size size) {
    final dress = Paint()..color = const Color(0xFFB8A5E5);
    final head = Paint()..color = const Color(0xFFFFE8D8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.6), width: size.width * 0.6, height: size.height * 0.6),
      dress,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.2,
      head,
    );
    _drawSimpleFace(
      canvas,
      center: Offset(size.width * 0.5, size.height * 0.25),
      eyeSpacing: 11,
      eyeColor: const Color(0xFF463B4F),
      smileWidth: 14,
    );
  }

  @override
  bool shouldRepaint(covariant _PersonSpritePainter oldDelegate) => oldDelegate.type != type;

  void _drawSimpleFace(
    Canvas canvas, {
    required Offset center,
    required double eyeSpacing,
    required Color eyeColor,
    required double smileWidth,
  }) {
    canvas.drawCircle(
      center.translate(-eyeSpacing / 2, -6),
      2,
      Paint()..color = eyeColor,
    );
    canvas.drawCircle(
      center.translate(eyeSpacing / 2, -6),
      2,
      Paint()..color = eyeColor,
    );
    final smile = Path()
      ..moveTo(center.dx - smileWidth / 2, center.dy + 4)
      ..quadraticBezierTo(center.dx, center.dy + 8, center.dx + smileWidth / 2, center.dy + 4);
    canvas.drawPath(
      smile,
      Paint()
        ..color = eyeColor.withOpacity(0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _NpcMoodOption {
  _NpcMoodOption({
    required this.label,
    required this.builder,
    this.isActive = false,
  });

  final String label;
  final String Function(int trees) builder;
  bool isActive;

  String messageForTrees(int trees) => builder(trees);
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
