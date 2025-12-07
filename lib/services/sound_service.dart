import 'package:audioplayers/audioplayers.dart';

import 'preferences_service.dart';

/// Centralizes calm sound effects so we can keep consistent volume/style.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _bubblePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setVolume(0.4);

  Future<void> playBubblePop() async {
    try {
      final enabled =
          await PreferencesService.instance.getSoundEnabled();
      if (!enabled) {
        await _bubblePlayer.stop();
        return;
      }
      await _bubblePlayer.stop();
      await _bubblePlayer.play(AssetSource('sounds/bubble_pop.wav'));
    } catch (_) {
      // Audio is optional; ignore device issues silently to keep calm UX.
    }
  }
}
