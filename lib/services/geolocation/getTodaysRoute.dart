import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import 'package:su_track/services/auth/loggedIn.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


  Future<List<LatLng>> fetchRoute(String currentDate) async {
    print('gjdflkgjhdfljkhfdljkhfdjklhgdruilf');
    try {
      final authData = await LoggedIn.getAuthData();
      final url = Uri.parse('${constants.baseUrl}/geolocation_api/get_today_route.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authData['token']}',
        },
        body: jsonEncode({
          "um_id": authData['um_Id'],
          "date": currentDate,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['route'] as List).map((point) {
            return LatLng(
              double.parse(point['latitude']),
              double.parse(point['longitude']),
            );
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return [];
  }

