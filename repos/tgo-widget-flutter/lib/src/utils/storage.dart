import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage utility for persisting data
class TgoStorage {
  static SharedPreferences? _prefs;

  /// Initialize the storage
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static Future<SharedPreferences> get prefs async {
    await init();
    return _prefs!;
  }

  /// Store a string value
  static Future<bool> setString(String key, String value) async {
    final p = await prefs;
    return p.setString(key, value);
  }

  /// Get a string value
  static Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  /// Store a JSON object
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return setString(key, jsonEncode(value));
  }

  /// Get a JSON object
  static Future<Map<String, dynamic>?> getJson(String key) async {
    final str = await getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Remove a value
  static Future<bool> remove(String key) async {
    final p = await prefs;
    return p.remove(key);
  }

  /// Clear all storage
  static Future<bool> clear() async {
    final p = await prefs;
    return p.clear();
  }

  /// Generate cache key for visitor
  static String visitorCacheKey(String apiBase, String apiKey) {
    return 'tgo:visitor:$apiBase:$apiKey';
  }
}

