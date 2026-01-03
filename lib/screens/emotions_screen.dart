import 'package:flutter/material.dart';

import '../models/avatar_profile.dart';
import '../models/emotion_entry.dart';
import '../services/avatar_storage_service.dart';
import '../services/session_log_service.dart';
import '../services/storage_service.dart';
import '../widgets/avatar_preview.dart';

class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({Key? key}) : super(key: key);

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen> {
  final StorageService _storageService = StorageService();
  final AvatarStorageService _avatarStorage = AvatarStorageService();
  final SessionLogService _sessionLog = SessionLogService.instance;
  final TextEditingController _noteController = TextEditingController();
  List<EmotionEntry> _entries = [];
  AvatarProfile? _avatarProfile;
  final List<String> _emotions = const [
    'Feliz',
    'Calmado',
    'Triste',
    'Asustado',
    'Enfadado',
  ];

  String? _selectedEmotion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadAvatar();
  }

  Future<void> _loadEntries() async {
    final entries = await _storageService.loadEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _loadAvatar() async {
    final profile = await _avatarStorage.loadProfile();
    if (!mounted) return;
    setState(() {
      _avatarProfile = profile;
    });
  }

  Future<void> _saveEmotion() async {
    if (_selectedEmotion == null || _isSaving) {
      if (_selectedEmotion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, elige una emoción primero.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final entry = EmotionEntry(
      date: DateTime.now(),
      emotion: _selectedEmotion!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await _storageService.addEntry(entry);
      await _sessionLog.logEmotionEntry(
        emotion: entry.emotion,
        note: entry.note,
      );

      if (!mounted) return;

      setState(() {
        _noteController.clear();
        _selectedEmotion = null;
        _entries = [..._entries, entry];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emoción guardada')),
      );
    } catch (error, stack) {
      debugPrint('Emotion save failed: $error');
      debugPrint('$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la emoción.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteEntry(EmotionEntry entry) async {
    setState(() {
      _entries = _entries.where((e) => e != entry).toList();
    });
    await _storageService.saveEntries(_entries);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrada eliminada')),
    );
  }

  Map<String, int> _emotionCounts() {
    final counts = <String, int>{};
    for (final entry in _entries) {
      counts.update(entry.emotion, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emociones'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_avatarProfile != null) ...[
              Center(
                child: Column(
                  children: [
                    AvatarPreview(profile: _avatarProfile!, size: 150),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu amigo pregunta:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5F7D95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              '¿Cómo te sentiste hoy?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6FA5),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _emotions.map((emotion) {
                final isSelected = emotion == _selectedEmotion;
                return ChoiceChip(
                  label: Text(emotion),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedEmotion = isSelected ? null : emotion;
                    });
                  },
                  selectedColor: const Color(0xFF8FB3FF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4A6FA5),
                  ),
                  backgroundColor: const Color(0xFFE3ECFF),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_entries.isNotEmpty) ...[
              _EmotionSummary(counts: _emotionCounts()),
              const SizedBox(height: 20),
            ],
            const Text(
              '¿Quieres añadir una nota?',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF5F7D95),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                  hintText: 'Escribe algo suave aquí...',
                filled: true,
                fillColor: const Color(0xFFF7F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEmotion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF8FB3FF),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Tu diario espera la primera emoción.',
                        style: TextStyle(color: Color(0xFF5F7D95)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[_entries.length - 1 - index];
                        return Dismissible(
                          key: ValueKey('${entry.date.toIso8601String()}_${entry.emotion}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC1C1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Color(0xFF8C4351)),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                            title: const Text('¿Eliminar entrada?'),
                            content: const Text(
                                '¿Quieres borrar esta entrada del diario?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Conservar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) => _deleteEntry(entry),
                          child: _EmotionEntryCard(entry: entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionEntryCard extends StatelessWidget {
  const _EmotionEntryCard({required this.entry});

  final EmotionEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.date;
    final dateText =
        '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    final timeText =
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.emotion,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A6FA5),
                ),
              ),
              Text(
                '$dateText · $timeText',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A8AA6),
                ),
              ),
            ],
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.note!,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF5F7D95),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _EmotionSummary extends StatelessWidget {
  const _EmotionSummary({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Susurros de tu ánimo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF35527D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: items
                .map(
                  (entry) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        color: Color(0xFF4A6FA5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
