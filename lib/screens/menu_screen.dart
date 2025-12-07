import 'package:flutter/material.dart';

import '../minigames/bubble_calm_screen.dart';
import '../minigames/seed_garden_screen.dart';
import '../minigames/star_path_screen.dart';
import 'avatar_screen.dart';
import 'emotions_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        title: 'Bubble Calm',
        subtitle: 'Relaxing bubbles',
        builder: () => const BubbleCalmScreen(),
      ),
      _MenuItem(
        title: 'Star Path',
        subtitle: 'Draw stars and lines',
        builder: () => const StarPathScreen(),
      ),
      _MenuItem(
        title: 'Seed Garden',
        subtitle: 'Plant small seeds',
        builder: () => const SeedGardenScreen(),
      ),
      _MenuItem(
        title: 'Emotions',
        subtitle: 'How I feel today',
        builder: () => const EmotionsScreen(),
      ),
      _MenuItem(
        title: 'Create My Avatar',
        subtitle: 'Design a calm friend',
        builder: () => const AvatarScreen(),
      ),
      _MenuItem(
        title: 'Calm Settings',
        subtitle: 'Info & soft preferences',
        builder: () => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BrisaKids'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MenuCard(item: item);
          },
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
  });

  final String title;
  final String subtitle;
  final Widget Function() builder;
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
          color: const Color(0xFFF1F6FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6FA5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F7D95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
