import 'package:shared_preferences/shared_preferences.dart';

class ExperienceFlagsService {
  ExperienceFlagsService._();

  static final ExperienceFlagsService instance = ExperienceFlagsService._();

  static const String _prefix = 'expflag_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> wasShown(String id) async {
    final prefs = await _ensurePrefs();
    return prefs.getBool('$_prefix$id') ?? false;
  }

  Future<void> markShown(String id) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool('$_prefix$id', true);
  }
}
