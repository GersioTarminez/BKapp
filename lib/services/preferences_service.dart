import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  static const _soundKey = 'pref_sound_enabled';
  static const _introKey = 'pref_show_intro';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> getSoundEnabled() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_soundKey, enabled);
  }

  Future<bool> getIntroVisible() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_introKey) ?? true;
  }

  Future<void> setIntroVisible(bool visible) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_introKey, visible);
  }
}
