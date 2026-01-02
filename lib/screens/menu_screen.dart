import 'package:flutter/material.dart';

import '../minigames/bubble_calm_screen.dart';
import '../minigames/seed_garden_screen.dart';
import '../minigames/star_path_screen.dart';
import 'emotions_screen.dart';
import 'other_activities_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameItems = [
      _MenuItem(
        title: 'Calma de Burbujas',
        subtitle: 'Burbujas para relajarte',
        builder: () => const BubbleCalmScreen(),
        gradient: const [
          Color(0xFFA8C8FF),
          Color(0xFF7BA8FF),
        ],
        icon: Icons.bubble_chart,
      ),
      _MenuItem(
        title: 'Camino de Estrellas',
        subtitle: 'Dibuja constelaciones calmadas',
        builder: () => const StarPathScreen(),
        gradient: const [
          Color(0xFFFFD9A3),
          Color(0xFFFFB87A),
        ],
        icon: Icons.auto_graph,
      ),
      _MenuItem(
        title: 'Jardín de Semillas',
        subtitle: 'Planta y cuida tu bosque',
        builder: () => const SeedGardenScreen(),
        gradient: const [
          Color(0xFF8EE3B0),
          Color(0xFF5EC08E),
        ],
        icon: Icons.grass,
      ),
      _MenuItem(
        title: 'Modo Emociones',
        subtitle: 'Elige cómo te sientes hoy',
        builder: () => const EmotionsScreen(),
        gradient: const [
          Color(0xFFFFB5DE),
          Color(0xFFFED4E8),
        ],
        icon: Icons.emoji_emotions,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BrisaKids'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Juegos calmados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35527D),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 520;
                final itemWidth = isWide
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: gameItems
                      .map(
                        (item) => SizedBox(
                          width: itemWidth,
                          child: _MenuCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Más actividades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF35527D),
              ),
            ),
            const SizedBox(height: 12),
            const _OthersButton(),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.builder,
    this.gradient,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget Function() builder;
  final List<Color>? gradient;
  final IconData? icon;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.builder()),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          gradient: item.gradient != null
              ? LinearGradient(
                  colors: item.gradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: item.gradient == null ? const Color(0xFFF1F6FF) : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
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
}

class _OthersButton extends StatelessWidget {
  const _OthersButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtherActivitiesScreen()),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF35527D),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          children: const [
            Icon(Icons.apps, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Otras experiencias',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Emociones, avatar, ajustes y más',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}
