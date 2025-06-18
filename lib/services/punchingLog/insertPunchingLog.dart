import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:su_track/util/constants.dart' as constants;
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<Map<String, dynamic>> insertPunchingLog({
  required BuildContext context,
  required int? direction,
}) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/punching_log_api/insert_punching_log.php');
  final logDate = DateTime.now().toString();
  final body = jsonEncode({
    "um_id": authData['um_Id'],
    "username": authData['universal_Id'],
    "LogDate": logDate,
    "db": authData['db'],
    "direction": direction
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
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(responseData);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );
      return {
        'success': true,
        'punching_count': int.parse(responseData['punching_count']),
      };
    } else if (response.statusCode == 403){
      Future.delayed(Duration(milliseconds: 5), () {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can be logged in only in 1 device so you are being logged out')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter correct aadhaar number')),
      );
    }
  } catch (e) {

  }
  return {'success': false, 'punching_count': 0};
}
