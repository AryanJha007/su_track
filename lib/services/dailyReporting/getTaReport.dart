import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import '../auth/loggedIn.dart';



Future<List<Map<String, dynamic>>> fetchTAReport( {required int month,
    required int year}) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/daily_reporting_api/getTa.php');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json','Authorization': 'Bearer ${authData['token']}',},
    body: jsonEncode({'um_id': authData['um_Id'], 'user_id': authData['universal_Id'],'month': month,
      'year': year,}),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch TA data.');
    }
  } else {
    throw Exception('Server Error: ${response.statusCode}');
  }
}
