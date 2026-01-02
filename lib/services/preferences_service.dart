import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  static const _soundKey = 'pref_sound_enabled';
  static const _introKey = 'pref_show_intro';
  static const _userNameKey = 'pref_user_name';

  SharedPreferences? _prefs;
  String? _cachedUserName;

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

  String get cachedUserName => _cachedUserName ?? 'anonymous';

  Future<String> getUserName() async {
    final prefs = await _ensurePrefs();
    final name = prefs.getString(_userNameKey) ?? 'anonymous';
    _cachedUserName = name;
    return name;
  }

  Future<void> setUserName(String name) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_userNameKey, name);
    _cachedUserName = name;
  }
}
