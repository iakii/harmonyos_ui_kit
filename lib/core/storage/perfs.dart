// ignore_for_file: non_constant_identifier_names

import 'package:shared_preferences/shared_preferences.dart';

class _Perfs {
  _Perfs._();
  static final _Perfs instance = _Perfs._();

  String KEY_JS = 'key_js-local';

  late SharedPreferences _prefs;
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> put(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  List<String>? getStringListOr(String key) {
    return _prefs.getStringList(key);
  }

  Future<void> putStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> putString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> putBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  Future<void> putDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  SharedPreferences get it => _prefs;
}

final perfs = _Perfs.instance;
