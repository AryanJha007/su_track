import 'package:http/http.dart' as http;
import 'dart:convert';


Future<List<Map<String, String>>> fetchStates() async {
  final response = await http.get(Uri.parse('https://hrms.sandipuniversity.com/Api/fetch_state'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, String>>.from(data['data'].map((state) => {
      'state_id': state['state_id'].toString(),
      'state_name': state['state_name'].toString(),
    }));
  } else {
    throw Exception('Failed to load states');
  }
}
  Future<List<Map<String, String>>> fetchCities(String stateId) async {
    final response = await http.post(
      Uri.parse('https://hrms.sandipuniversity.com/Api/fetch_cities'),
      body: jsonEncode({'state_id': stateId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        return List<Map<String, String>>.from(data['data'].map((city) => {
          'city_id': city['city_id'].toString(),
          'city_name': city['city_name'].toString(),
        }));
      } else {
        throw Exception('No cities found for the selected state');
      }
    }
    else {
      throw Exception('Failed to load cities');
    }
  }