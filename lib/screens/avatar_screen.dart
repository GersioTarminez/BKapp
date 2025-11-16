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
      const SnackBar(content: Text('Avatar saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create My Avatar'),
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
                    child: AvatarPreview(profile: _profile, size: 200),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Hair Style',
                    child: _buildChoiceWrap(
                      options: _hairTypes,
                      selected: _profile.hairType,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(hairType: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Hair Color',
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
                    title: 'Face Shape',
                    child: _buildChoiceWrap(
                      options: _faceTypes,
                      selected: _profile.faceType,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(faceType: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Expression',
                    child: _buildChoiceWrap(
                      options: _expressions,
                      selected: _profile.expression,
                      onSelect: (value) =>
                          _updateProfile(_profile.copyWith(expression: value)),
                    ),
                  ),
                  _buildSection(
                    title: 'Clothing',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChoiceWrap(
                          options: _shirtTypes,
                          selected: _profile.shirtType,
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
                    title: 'Footwear',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChoiceWrap(
                          options: _shoeTypes,
                          selected: _profile.shoesType,
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
                      child: Text(_isSaving ? 'Saving...' : 'Save Avatar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((item) {
        final isSelected = selected == item;
        return ChoiceChip(
          label: Text(_capitalize(item)),
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

  void _updateProfile(AvatarProfile profile) {
    setState(() {
      _profile = profile;
    });
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
