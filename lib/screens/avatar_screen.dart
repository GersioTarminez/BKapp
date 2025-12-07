import 'package:flutter/material.dart';

import '../models/avatar_profile.dart';
import '../services/avatar_storage_service.dart';
import '../widgets/avatar_preview.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  final AvatarStorageService _storageService = AvatarStorageService();
  AvatarProfile _profile = AvatarProfile.defaults();
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _hairTypes = [
    'short',
    'long',
    'curly',
    'straight',
    'pony',
    'bald',
  ];
  final List<String> _faceTypes = ['round', 'oval', 'square'];
  final List<String> _expressions = ['neutral', 'smile', 'happy'];
  final List<String> _shirtTypes = ['basic', 'stripe', 'hoodie'];
  final List<String> _shoeTypes = ['simple', 'sneakers', 'boots'];
  final List<String> _companionTypes = ['dog', 'cat', 'hamster'];

  final List<Color> _hairColors = [
    const Color(0xFFFFD1DC),
    const Color(0xFF8C756A),
    const Color(0xFFBFA5A0),
    const Color(0xFF5D5F71),
    const Color(0xFFF0C987),
  ];

  final List<Color> _clothingColors = [
    const Color(0xFFA4E4AF),
    const Color(0xFFB6E0FE),
    const Color(0xFFFFD6A5),
    const Color(0xFFD8C3FF),
    const Color(0xFFFFF1C1),
  ];

  final List<Color> _shoeColors = [
    const Color(0xFFD8CFFF),
    const Color(0xFFB0D9FF),
    const Color(0xFFE5B3FE),
    const Color(0xFFCBC0FF),
    const Color(0xFFFFE6EB),
  ];

  final Map<String, String> _hairLabels = const {
    'short': 'Corto',
    'long': 'Largo',
    'curly': 'Rizado',
    'straight': 'Liso',
    'pony': 'Coleta',
    'bald': 'Sin pelo',
  };

  final Map<String, String> _faceLabels = const {
    'round': 'Redondo',
    'oval': 'Ovalado',
    'square': 'Cuadrado',
  };

  final Map<String, String> _expressionLabels = const {
    'neutral': 'Neutral',
    'smile': 'Sonrisa',
    'happy': 'Muy feliz',
  };

  final Map<String, String> _shirtLabels = const {
    'basic': 'Básica',
    'stripe': 'Rayas suaves',
    'hoodie': 'Sudadera',
  };

  final Map<String, String> _shoeLabels = const {
    'simple': 'Sencillos',
    'sneakers': 'Zapatillas',
    'boots': 'Botas',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final saved = await _storageService.loadProfile();
    setState(() {
      _profile = saved ?? AvatarProfile.defaults();
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await _storageService.saveProfile(_profile);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Avatar guardado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Crear mi avatar'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        AvatarPreview(profile: _profile, size: 200),
                        const SizedBox(height: 8),
                        Text(
                          'Compañero: ${_companionLabel(_profile.companionType)}',
                          style: const TextStyle(
                            color: Color(0xFF4A6FA5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Toca los botones para cambiar colores, formas y elegir un compañero calmado.',
                    style: TextStyle(
                      color: Color(0xFF5F7D95),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Peinado',
                    child: _buildChoiceWrap(
                      options: _hairTypes,
                      selected: _profile.hairType,
                      labelBuilder: _hairLabel,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(hairType: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Color del pelo',
                    child: _buildColorWrap(
                      options: _hairColors,
                      selectedHex: _profile.hairColor,
                      onSelect: (color) => _updateProfile(
                        _profile.copyWith(
                          hairColor: AvatarProfile.colorToHex(color),
                        ),
                      ),
                    ),
                  ),
                  _buildSection(
                    title: 'Forma del rostro',
                    child: _buildChoiceWrap(
                      options: _faceTypes,
                      selected: _profile.faceType,
                      labelBuilder: _faceLabel,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(faceType: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Expresión',
                    child: _buildChoiceWrap(
                      options: _expressions,
                      selected: _profile.expression,
                      labelBuilder: _expressionLabel,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(expression: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Ropa',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChoiceWrap(
                          options: _shirtTypes,
                          selected: _profile.shirtType,
                          labelBuilder: _shirtLabel,
                          onSelect: (value) => _updateProfile(
                            _profile.copyWith(shirtType: value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildColorWrap(
                          options: _clothingColors,
                          selectedHex: _profile.shirtColor,
                          onSelect: (color) => _updateProfile(
                            _profile.copyWith(
                              shirtColor: AvatarProfile.colorToHex(color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Calzado',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChoiceWrap(
                          options: _shoeTypes,
                          selected: _profile.shoesType,
                          labelBuilder: _shoeLabel,
                          onSelect: (value) =>
                              _updateProfile(_profile.copyWith(shoesType: value)),
                        ),
                        const SizedBox(height: 8),
                        _buildColorWrap(
                          options: _shoeColors,
                          selectedHex: _profile.shoesColor,
                          onSelect: (color) => _updateProfile(
                            _profile.copyWith(
                              shoesColor: AvatarProfile.colorToHex(color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Compañero calmado',
                    child: _buildCompanionRow(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF8FB3FF),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(_isSaving ? 'Guardando...' : 'Guardar avatar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const Divider(height: 16, thickness: 0.8),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    String Function(String)? labelBuilder,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((item) {
        final isSelected = selected == item;
        return ChoiceChip(
          label: Text(labelBuilder?.call(item) ?? _capitalize(item)),
          selected: isSelected,
          selectedColor: const Color(0xFF8FB3FF),
          backgroundColor: const Color(0xFFE0E7FF),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4A6FA5),
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onSelect(item),
        );
      }).toList(),
    );
  }

  Widget _buildColorWrap({
    required List<Color> options,
    required String selectedHex,
    required ValueChanged<Color> onSelect,
  }) {
    final selectedColor = AvatarProfile.colorFromHex(selectedHex);
    return Wrap(
      spacing: 12,
      children: options.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF4A6FA5) : Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanionRow() {
    return Wrap(
      spacing: 12,
      children: _companionTypes.map((type) {
        final isSelected = _profile.companionType == type;
        return GestureDetector(
          onTap: () => _updateProfile(_profile.copyWith(companionType: type)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8FB3FF).withOpacity(0.2)
                  : const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF8FB3FF) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF8FB3FF).withOpacity(0.25),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _companionEmoji(type),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  _companionLabel(type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF35527D) : const Color(0xFF4A6FA5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _updateProfile(AvatarProfile profile) {
    setState(() {
      _profile = profile;
    });
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  String _hairLabel(String value) => _hairLabels[value] ?? _capitalize(value);
  String _faceLabel(String value) => _faceLabels[value] ?? _capitalize(value);
  String _expressionLabel(String value) =>
      _expressionLabels[value] ?? _capitalize(value);
  String _shirtLabel(String value) => _shirtLabels[value] ?? _capitalize(value);
  String _shoeLabel(String value) => _shoeLabels[value] ?? _capitalize(value);

  String _companionLabel(String value) {
    switch (value) {
      case 'cat':
        return 'Gato';
      case 'hamster':
        return 'Hámster';
      case 'dog':
      default:
        return 'Perro';
    }
  }

  String _companionEmoji(String type) {
    switch (type) {
      case 'cat':
        return '🐱';
      case 'hamster':
        return '🐹';
      case 'dog':
      default:
        return '🐶';
    }
  }
}
