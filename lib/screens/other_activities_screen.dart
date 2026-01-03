import 'package:flutter/material.dart';

import 'avatar_screen.dart';
import 'session_info_screen.dart';
import 'settings_screen.dart';

class OtherActivitiesScreen extends StatelessWidget {
  const OtherActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _OtherItem(
        icon: Icons.person_pin,
        title: 'Crear mi Avatar',
        subtitle: 'Elige un amigo acompañante',
        builder: () => const AvatarScreen(),
      ),
      _OtherItem(
        icon: Icons.settings_outlined,
        title: 'Ajustes Calmos',
        subtitle: 'Información y preferencias',
        builder: () => const SettingsScreen(),
      ),
      _OtherItem(
        icon: Icons.insights_outlined,
        title: 'Información de sesión',
        subtitle: 'Resumen de tu juego',
        builder: () => const SessionInfoScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _OtherIntro();
          }
          final item = items[index - 1];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE3ECFF),
                child: Icon(item.icon, color: const Color(0xFF35527D)),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF35527D),
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: const TextStyle(
                  color: Color(0xFF5F7D95),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.builder()),
                );
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length + 1,
      ),
    );
  }
}

class _OtherItem {
  _OtherItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;
}

class _OtherIntro extends StatelessWidget {
  const _OtherIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Personaliza tu experiencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF35527D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aquí puedes crear tu avatar, revisar ajustes calmados y consultar los reportes de sesión. '
            'Todo está pensado para que configures la app a tu ritmo.',
            style: TextStyle(
              color: Color(0xFF5F7D95),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
