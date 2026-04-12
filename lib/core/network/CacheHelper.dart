import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
  static SharedPreferences sharedPreferences = init();

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  /// Per-user snapshot written on sign-out (email, compound id, compounds map).
  static String cachedUserDataKey(String userId) => 'cached_data_$userId';

  static Future<void> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await asyncPrefs.setString(key, value);
    if (value is int) return await asyncPrefs.setInt(key, value);
    if (value is bool) return await asyncPrefs.setBool(key, value);
    if (value is double) return await asyncPrefs.setDouble(key, value);
  }

  static Future<dynamic> getData({
    required String key,
    required String type,
  }) async {
    if (type == "String") return await asyncPrefs.getString(key);
    if (type == "int") return await asyncPrefs.getInt(key);
    if (type == "bool") return await asyncPrefs.getBool(key);
    if (type == "double") return await asyncPrefs.getDouble(key);
  }

  static Future<void> removeData(String key) async {
    await asyncPrefs.remove(key);
  }

  /// Stores a JSON object as a UTF-8 string (maps, lists, primitives).
  static Future<void> saveJson(String key, Object? value) async {
    await saveData(key: key, value: jsonEncode(value));
  }

  /// Reads and decodes JSON; returns null if missing or invalid.
  static Future<dynamic> getJson(String key) async {
    final raw = await getData(key: key, type: "String") as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
