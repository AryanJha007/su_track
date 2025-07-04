import 'package:http/http.dart' as http;
import 'package:su_track/services/auth/loggedIn.dart';
import 'dart:convert';
import 'package:su_track/util/constants.dart' as constants;

Future<void> updateGeolocation(String latitude, String longitude) async {

  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/geolocation_api/add_update_user_geolocation.php');
  final body = jsonEncode({
    "um_id": authData['um_Id'],
    "latitude": latitude,
    "longitude": longitude,
  });
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authData['token']}',
      },
      body: body,
    );
    print(authData['um_Id'] );
    if (response.statusCode == 200) {
      print(DateTime.now().toString());
    } else {
      // Handle failure
    }
  } catch (e) {
    // Handle exception
  }
}
