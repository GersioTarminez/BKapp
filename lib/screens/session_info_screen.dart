import 'package:flutter/material.dart';

import '../services/session_stats_service.dart';

class SessionInfoScreen extends StatelessWidget {
  const SessionInfoScreen({super.key});

  Future<_SessionData> _loadAllSessions() async {
    final service = SessionStatsService.instance;
    final bubbles = await service.loadSessions();
    final garden = await service.loadGardenSessions();
    return _SessionData(
      bubbles: bubbles,
      garden: garden,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de sesión'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_SessionData>(
        future: _loadAllSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? const _SessionData();
          final bubbles = data.bubbles;
          final garden = data.garden;
          if (bubbles.isEmpty && garden.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay sesiones guardadas. Juega y cuida el jardín para comenzar a registrar tus datos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (bubbles.isNotEmpty) ...[
                const _SectionHeader('Calma de Burbujas'),
                const SizedBox(height: 12),
                ...bubbles
                    .reversed
                    .map((session) => _BubbleSessionCard(session: session)),
                const SizedBox(height: 24),
              ],
              if (garden.isNotEmpty) ...[
                const _SectionHeader('Jardín de Semillas'),
                const SizedBox(height: 12),
                ...garden
                    .reversed
                    .map((session) => _GardenSessionCard(session: session)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF35527D),
      ),
    );
  }
}

class _BubbleSessionCard extends StatelessWidget {
  const _BubbleSessionCard({required this.session});

  final BubbleSessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesión ${session.startedAt.toLocal()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35527D),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricChip(
                  label: 'Burbujas',
                  value: session.bubblesPopped.toString(),
                ),
                _MetricChip(
                  label: 'Fallos',
                  value: session.missedTaps.toString(),
                ),
                _MetricChip(
                  label: 'Velocidad',
                  value: session.meanIntervalMs == null
                      ? '-'
                      : '${session.meanIntervalMs!.toStringAsFixed(0)} ms',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenSessionCard extends StatelessWidget {
  const _GardenSessionCard({required this.session});

  final GardenSessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesión ${session.startedAt.toLocal()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F5B3A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricChip(
                  label: 'Árboles',
                  value: session.treesPlanted.toString(),
                ),
                _MetricChip(
                  label: 'Flores',
                  value: session.flowersPlanted.toString(),
                ),
                _MetricChip(
                  label: 'Tiempo',
                  value: _formatDuration(session.durationSeconds),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '-';
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).round();
    if (minutes == 0) {
      return '$remaining s';
    }
    return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF5F7D95),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF35527D),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionData {
  const _SessionData({
    this.bubbles = const [],
    this.garden = const [],
  });

  final List<BubbleSessionSummary> bubbles;
  final List<GardenSessionSummary> garden;
}
