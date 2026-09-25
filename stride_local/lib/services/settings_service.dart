import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const _nameKey = 'profile_name';
  static const _weightKey = 'profile_weight_kg';
  static const _unitKey = 'distance_unit';
  static const _themeKey = 'theme_mode';

  Future<String> getName() => _prefs.getString(_nameKey).then((v) => v ?? 'Athlete');

  Future<double> getWeight() async => (await _prefs.getDouble(_weightKey)) ?? 70;

  Future<String> getUnit() async => (await _prefs.getString(_unitKey)) ?? 'km';

  Future<String> getTheme() async => (await _prefs.getString(_themeKey)) ?? 'system';

  Future<void> saveName(String value) => _prefs.setString(_nameKey, value);

  Future<void> saveWeight(double value) => _prefs.setDouble(_weightKey, value);

  Future<void> saveUnit(String value) => _prefs.setString(_unitKey, value);

  Future<void> saveTheme(String value) => _prefs.setString(_themeKey, value);
}
