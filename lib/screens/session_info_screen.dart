import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/drawing_storage_service.dart';
import '../services/export_service.dart';
import '../services/session_log_service.dart';

class SessionInfoScreen extends StatefulWidget {
  const SessionInfoScreen({super.key});

  @override
  State<SessionInfoScreen> createState() => _SessionInfoScreenState();
}

class _SessionInfoScreenState extends State<SessionInfoScreen> {
  bool _isTxtExporting = false;

  Future<_SessionData> _loadAllSessions() async {
    final service = SessionLogService.instance;
    final bubbles = await service.loadSessions(game: SessionGame.bubbleCalm);
    final garden = await service.loadSessions(game: SessionGame.seedGarden);
    final starPaths = await DrawingStorageService.instance.loadStarPathRecords();
    return _SessionData(
      bubbles: bubbles,
      garden: garden,
      starPaths: starPaths,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de sesión'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _openExportSheet(context),
            icon: const Icon(Icons.download),
            tooltip: 'Exportar sesiones',
          ),
        ],
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
          final starPaths = data.starPaths;
          if (bubbles.isEmpty && garden.isEmpty && starPaths.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay sesiones guardadas. Crea caminos de estrellas o juega a los minijuegos para registrar datos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Builder(builder: (buttonContext) {
                    return ElevatedButton.icon(
                      onPressed: _isTxtExporting
                          ? null
                          : () => _exportSessionsTxt(buttonContext),
                      icon: _isTxtExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.description_outlined),
                      label: Text(
                        _isTxtExporting
                            ? 'Exportando...'
                            : 'Exportar sesiones (.txt)',
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const SizedBox(height: 24),
                    ],
                    if (starPaths.isNotEmpty) ...[
                      const _SectionHeader('Camino de Estrellas'),
                      const SizedBox(height: 12),
                      ...starPaths
                          .map((record) => _StarPathRecordCard(record: record)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_view),
                title: const Text('Exportar como XLSX'),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportSessions(context: context, asXlsx: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Exportar como CSV'),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportSessions(context: context, asXlsx: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportSessions({
    required BuildContext context,
    required bool asXlsx,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    try {
      await ExportService.instance.exportSessions(asXlsx: asXlsx);
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _exportSessionsTxt(BuildContext context) async {
    if (_isTxtExporting) return;
    setState(() => _isTxtExporting = true);
    String? errorMessage;
    Rect? shareOrigin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final offset = box.localToGlobal(Offset.zero);
        shareOrigin = offset & box.size;
      }
    } catch (_) {}
    try {
      await ExportService.instance.exportSessionsTxt(
        shareOrigin: shareOrigin,
      );
    } catch (error, stack) {
      errorMessage = 'No se pudo exportar la sesión.';
      debugPrint('TXT EXPORT ERROR: $error');
      debugPrint('$stack');
    } finally {
      if (mounted) {
        setState(() => _isTxtExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage ?? 'Archivo .txt generado.',
            ),
          ),
        );
      }
    }
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

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    final metrics = session.metrics;
    final mean = metrics['mean_tap_interval_ms'] as num?;
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
                  value: '${metrics['bubbles_popped'] ?? 0}',
                ),
                _MetricChip(
                  label: 'Fallos',
                  value: '${metrics['missed_taps'] ?? 0}',
                ),
                _MetricChip(
                  label: 'Velocidad',
                  value: mean == null ? '-' : '${mean.toStringAsFixed(0)} ms',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Usuario: ${session.userName}',
              style: const TextStyle(
                color: Color(0xFF6B7C9C),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenSessionCard extends StatelessWidget {
  const _GardenSessionCard({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    final metrics = session.metrics;
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
                  value: '${metrics['trees_planted'] ?? 0}',
                ),
                _MetricChip(
                  label: 'Flores',
                  value: '${metrics['flowers_planted'] ?? 0}',
                ),
                _MetricChip(
                  label: 'Tiempo',
                  value: _formatDuration(session.durationSeconds),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Usuario: ${session.userName}',
              style: const TextStyle(
                color: Color(0xFF4E6C93),
                fontSize: 13,
              ),
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

class _StarPathRecordCard extends StatelessWidget {
  const _StarPathRecordCard({required this.record});

  final StarPathRecord record;

  @override
  Widget build(BuildContext context) {
    final hasMemoryThumb =
        record.thumbnailBytes != null && record.thumbnailBytes!.isNotEmpty;
    final File? thumbnailFile = (!kIsWeb && record.thumbnailPath.isNotEmpty)
        ? File(record.thumbnailPath)
        : null;
    final hasThumbnailFile =
        thumbnailFile != null && thumbnailFile.existsSync();
    final metrics = record.metrics;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasMemoryThumb
                  ? Image.memory(
                      record.thumbnailBytes!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : hasThumbnailFile
                      ? Image.file(
                          thumbnailFile!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 110,
                          height: 110,
                          color: const Color(0xFFE0E6FF),
                          child: const Icon(Icons.broken_image,
                              color: Color(0xFF5C6CA8)),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.word ?? 'Modo libre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E66),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Usuario: ${record.userName}',
                  style: const TextStyle(
                    color: Color(0xFF6F82A4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sesión ${record.savedAt.toLocal()}',
                  style: const TextStyle(
                    color: Color(0xFF7A8DAA),
                    fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _MetricChip(
                        label: 'Estrellas',
                        value:
                            '${metrics['stars_placed_count'] ?? '-'}',
                      ),
                      _MetricChip(
                        label: 'Longitud',
                        value:
                            (metrics['path_length_total'] as num?)
                                    ?.toStringAsFixed(1) ??
                                '-',
                      ),
                      _MetricChip(
                        label: 'Modo',
                        value: record.mode.toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    this.starPaths = const [],
  });

  final List<SessionRecord> bubbles;
  final List<SessionRecord> garden;
  final List<StarPathRecord> starPaths;
}
