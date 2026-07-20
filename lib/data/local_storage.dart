import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

/// Hive-based local cache for offline support.
/// Stores serialized JSON strings with timestamps.
class LocalStorage {
  static const String _boxName = 'audley_cache';
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Save data with a timestamp for freshness checking.
  static Future<void> save(String key, dynamic data) async {
    await _box.put(key, jsonEncode(data));
    await _box.put('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Retrieve cached data, or null if not found.
  static dynamic get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Check if cached data is still fresh.
  static bool isFresh(String key, {Duration? maxAge}) {
    final ts = _box.get('${key}_ts');
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - (ts as int);
    return age < (maxAge ?? AppConstants.cacheMaxAge).inMilliseconds;
  }

  /// Get a simple string value.
  static String? getString(String key) => _box.get(key)?.toString();

  /// Save a simple string value.
  static Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  /// Get a bool value.
  static bool getBool(String key, {bool defaultValue = false}) {
    final val = _box.get(key);
    if (val is bool) return val;
    if (val == 'true') return true;
    if (val == 'false') return false;
    return defaultValue;
  }

  /// Save a bool value.
  static Future<void> setBool(String key, bool value) async {
    await _box.put(key, value);
  }

  /// Delete a cached item.
  static Future<void> delete(String key) async {
    await _box.delete(key);
    await _box.delete('${key}_ts');
  }

  /// Clear all cache.
  static Future<void> clearAll() async {
    await _box.clear();
  }
}
