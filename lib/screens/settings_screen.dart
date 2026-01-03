import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferences = PreferencesService.instance;
  bool _soundOn = true;
  bool _showIntro = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sound = await _preferences.getSoundEnabled();
    final intro = await _preferences.getIntroVisible();
    if (!mounted) return;
    setState(() {
      _soundOn = sound;
      _showIntro = intro;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes calmos'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Preferencias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            title: 'Sonidos suaves',
            subtitle: 'Activa o desactiva los efectos calmados.',
            value: _soundOn,
            onChanged: (value) {
              setState(() => _soundOn = value);
              _preferences.setSoundEnabled(value);
            },
          ),
          _buildToggle(
            title: 'Mostrar mensaje inicial',
            subtitle: 'Enseña la frase de bienvenida en la pantalla principal.',
            value: _showIntro,
            onChanged: (value) {
              setState(() => _showIntro = value);
              _preferences.setIntroVisible(value);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Sobre BrisaKids',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.favorite,
            title: 'Propósito',
            description:
                'BrisaKids es un proyecto universitario que ofrece mini-juegos calmados y un diario emocional para niños en tratamientos largos.',
          ),
          _buildInfoCard(
            icon: Icons.shield_outlined,
            title: 'Privacidad',
            description:
                'Todos los datos se quedan en este dispositivo. No hay cuentas, ni analíticas, ni publicidad.',
          ),
          _buildInfoCard(
            icon: Icons.music_note,
            title: 'Arte y sonidos',
            description:
                'La app mezcla ilustraciones pastel propias con recursos libres seleccionados. Los sonidos son suaves y opcionales.',
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Versión 1.1.2\nSergio Martínez París · TFG',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F7D95),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFFF5F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF35527D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF5F7D95)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8FB3FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF35527D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F7D95),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
