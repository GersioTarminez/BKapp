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
        title: const Text('Calm Settings'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            title: 'Soft sounds',
            subtitle: 'Turn gentle effects on or off.',
            value: _soundOn,
            onChanged: (value) {
              setState(() => _soundOn = value);
              _preferences.setSoundEnabled(value);
            },
          ),
          _buildToggle(
            title: 'Show welcome tips',
            subtitle: 'Display the intro message on the home screen.',
            value: _showIntro,
            onChanged: (value) {
              setState(() => _showIntro = value);
              _preferences.setIntroVisible(value);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'About BrisaKids',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.favorite,
            title: 'Purpose',
            description:
                'BrisaKids is a university project that offers calm mini-games and a simple emotions diary for children facing long treatments.',
          ),
          _buildInfoCard(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            description:
                'All data stays on this device. No accounts, analytics, or advertisements are included.',
          ),
          _buildInfoCard(
            icon: Icons.music_note,
            title: 'Assets & sounds',
            description:
                'The app combines original pastel artwork with curated free assets. All sounds are gentle and optional.',
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version 0.1.0 – Alpha build\nSergio Martínez París · TFG',
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
