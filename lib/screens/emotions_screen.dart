import 'package:flutter/material.dart';

import '../models/avatar_profile.dart';
import '../models/emotion_entry.dart';
import '../services/avatar_storage_service.dart';
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
  final TextEditingController _noteController = TextEditingController();
  List<EmotionEntry> _entries = [];
  AvatarProfile? _avatarProfile;
  final List<String> _emotions = const [
    'Happy',
    'Calm',
    'Sad',
    'Scared',
    'Angry',
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
          const SnackBar(content: Text('Please choose an emotion first.')),
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

    await _storageService.addEntry(entry);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _noteController.clear();
      _selectedEmotion = null;
      _entries = [..._entries, entry];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emotion saved')),
    );
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
        title: const Text('Emotions'),
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
                      'Your friend asks:',
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
              'How did you feel today?',
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
            const Text(
              'Want to add a note?',
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
                hintText: 'Write something gentle here...',
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
                child: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Your diary is waiting for the first emotion.',
                        style: TextStyle(color: Color(0xFF5F7D95)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[_entries.length - 1 - index];
                        return _EmotionEntryCard(entry: entry);
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
