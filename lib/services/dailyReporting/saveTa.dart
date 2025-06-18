import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import '../auth/loggedIn.dart';

Future<bool> submitTotalTA({ required int calculatedTa, required int month, required int year}) async {
  final url = Uri.parse('${constants.baseUrl}/daily_reporting_api/saveTa.php');
  final authData = await LoggedIn.getAuthData();
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json','Authorization': 'Bearer ${authData['token']}',},
    body: jsonEncode({'um_id':  authData['um_Id'], 'calculated_ta': calculatedTa, 'month': month, 'year': year}),
  );
  print(response.body);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  } else {
    throw Exception('Failed to insert TA: ${response.statusCode}');
  }
}
