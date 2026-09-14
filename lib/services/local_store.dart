import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON key-value store on the device. Broadcasts a change event so
/// services can expose live streams without a network.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;
  final _changes = StreamController<String>.broadcast();

  Stream<String> get changes => _changes.stream;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> ready() async {
    await _p;
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = (await _p).getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    final raw = (await _p).getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await (await _p).setString(key, jsonEncode(value));
    _changes.add(key);
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await (await _p).setString(key, jsonEncode(value));
    _changes.add(key);
  }

  Future<String?> getString(String key) async => (await _p).getString(key);

  Future<void> setString(String key, String value) async {
    await (await _p).setString(key, value);
    _changes.add(key);
  }

  Future<void> remove(String key) async {
    await (await _p).remove(key);
    _changes.add(key);
  }

  Future<Set<String>> keys() async => (await _p).getKeys();
}
