import 'package:audioplayers/audioplayers.dart';

import 'preferences_service.dart';

/// Centralizes calm sound effects so we can keep consistent volume/style.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _bubblePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setVolume(0.4);
  final AudioPlayer _starPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop)
    ..setVolume(0.7);
  bool _starLooping = false;

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

  Future<void> startStarTrail() async {
    try {
      final enabled = await PreferencesService.instance.getSoundEnabled();
      if (!enabled) {
        await stopStarTrail();
        return;
      }
      if (_starLooping) return;
      await _starPlayer.stop();
      await _starPlayer.play(
        AssetSource('sounds/star_trail_loop.wav'),
      );
      _starLooping = true;
    } catch (_) {
      _starLooping = false;
    }
  }

  Future<void> stopStarTrail() async {
    try {
      await _starPlayer.stop();
    } finally {
      _starLooping = false;
    }
  }
}
