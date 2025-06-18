import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../auth/loggedIn.dart';

Future<int> fetchApprovedTA({
  required int month,
  required int year,
}) async {
  final url = Uri.parse('${constants.baseUrl}/daily_reporting_api/getApprovedTa.php');
  final authData = await LoggedIn.getAuthData();

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'um_id': authData['um_Id'], 'month': month, 'year': year}),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['approved_ta'] ?? 0;
    }
  }
  return 0;
}
