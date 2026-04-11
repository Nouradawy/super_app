import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper{
  static final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
  static SharedPreferences sharedPreferences = init();
  static init() async
  {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> saveData({
    required String key,
    required dynamic value,
  }) async {

    if(value is String ) return await asyncPrefs.setString(key, value);
    if(value is int ) return await asyncPrefs.setInt(key, value);
    if(value is bool ) return await asyncPrefs.setBool(key, value);
    if(value is double ) return await asyncPrefs.setDouble(key, value);

  }

  static Future<dynamic> getData({
    required String key,
    required String type,
  }) async {

    if(type == "String" ) return await asyncPrefs.getString(key);
    if(type == "int") return await asyncPrefs.getInt(key);
    if(type == "bool" ) return await asyncPrefs.getBool(key);
    if(type == "double" ) return await asyncPrefs.getDouble(key);


  }

}
