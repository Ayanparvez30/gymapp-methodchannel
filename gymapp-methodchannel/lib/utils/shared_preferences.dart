import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtils {
  static Future<void> saveUserToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_token', token);
  }
  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
   