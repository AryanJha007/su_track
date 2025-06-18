import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import '../auth/loggedIn.dart';

Future<bool> postTodayRoute(List<LatLng> routePoints) async {
  try {
    final authData = await LoggedIn.getAuthData();
    final url = Uri.parse('${constants.baseUrl}/geolocation_api/post_today_route.php');

    List<Map<String, dynamic>> routeData = routePoints.map((point) {
      return {
        'latitude': point.latitude.toString(),
        'longitude': point.longitude.toString(),
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData['token']}',
      },
      body: jsonEncode({
        "um_id": authData['um_Id'],
        "date": DateTime.now().toString().split(' ')[0],
        "route": routeData,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    }
  } catch (e) {
    print('Error posting route: $e');
  }
  return false;
}
