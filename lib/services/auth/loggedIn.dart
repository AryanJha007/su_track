import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoggedIn {
  static const String TOKEN_KEY = 'auth_token';
  static const String um_Id_KEY = 'um_Id';
  static const String aadhar_KEY = 'aadhar';
  static const String punch_status_KEY = 'isToggledIn';
  static const String universal_Id_key = 'universal_Id';
  static const String db_Key = 'db';
  static const String user_name_key = 'user_name';

  static Future<void> saveAuthData(
      String token, String um_Id, String? aadhar, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(um_Id_KEY, um_Id);
    await prefs.setString(user_name_key, userName);
    if (aadhar != null) {
      await prefs.setString(aadhar_KEY, aadhar);
    } else {
      await prefs.setString(aadhar_KEY, '');
    }
  }

  static Future<void> savePunchingStatus(bool punch_status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(punch_status_KEY, punch_status);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(TOKEN_KEY);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }
  static Future<void> saveRoutePoints(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? routePoints = prefs.getStringList('routePoints') ?? [];
    routePoints.add('${position.latitude},${position.longitude}');
    await prefs.setStringList('routePoints', routePoints);
  }

  static Future<List<LatLng>> fetchRoutePoints() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> routeStrings = prefs.getStringList('routePoints') ?? [];

    return routeStrings
        .map((routeString) {
      final parts = routeString.split(',');
      return LatLng(
        double.parse(parts[0]), // Latitude
        double.parse(parts[1]), // Longitude
      );
    })
        .toList();
  }

  static Future<bool> isPunchedIn()
  async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(punch_status_KEY)==true)
      {
        return true;
      }
    return false;
  }

  static Future<Map<String, dynamic>> getAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'token': prefs.getString(TOKEN_KEY),
        'um_Id': prefs.getString(um_Id_KEY),
        'aadhar': prefs.getString(aadhar_KEY),
        'universal_Id': prefs.getString(universal_Id_key),
        'db': prefs.getString(db_Key)
      };
    } catch (e) {
      print('Error fetching auth data: $e');

      return {};
    }
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(user_name_key) ;
  }

  static Future<void> setUniversalId(String universalId, String db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(universal_Id_key, universalId);
    await prefs.setString(db_Key, db);
  }
}
