import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../widgets/breathing_widget.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PreferencesService _preferences = PreferencesService.instance;
  bool _showIntroMessage = true;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadPreference();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPreference() async {
    final visible = await _preferences.getIntroVisible();
    final storedName = await _preferences.getUserName();
    if (!mounted) return;
    setState(() {
      _showIntroMessage = visible;
      _nameController.text = storedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: const Color(0xFFCBDEFF)),
          ),
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/brisakids_logo.png',
                  width: 360,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BrisaKids',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF35527D),
                      ),
                    ),
                    if (_showIntroMessage) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Un rincón tranquilo para explorar tus emociones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4E6C93),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Trabajo Final de Grado de Sergio Martínez París',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F3554),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Tu nombre',
                        hintText: 'Escribe cómo quieres identificarte',
                        labelStyle: const TextStyle(color: Color(0xFF4E6C93)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 52,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF8FB3FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _handleStart,
                      child: const Text('Comenzar'),
                    ),
                    const SizedBox(height: 28),
                    const BreathingWidget(),
                    const SizedBox(height: 12),
                    const Text(
                      'Respira despacio antes de entrar.',
                      style: TextStyle(
                        color: Color(0xFF4E6C93),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStart() async {
    final name = _nameController.text.trim().isEmpty
        ? 'anonymous'
        : _nameController.text.trim();
    await _preferences.setUserName(name);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }
}
