import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<List<Map<String, String>>> fetchWorkTypes(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final response = await http.get(
    Uri.parse('${constants.baseUrl}/daily_reporting_api/get_work_type.php?um_id=${authData['um_Id']} '),
    headers: {
  'Authorization': 'Bearer ${authData['token']}',
    },
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      List<Map<String, String>> workTypes = [];
      for (var user in responseData['work_type']) {
        workTypes.add({
          'work_type_id': user['work_type_id'],
          'work_type': user['work_type'],
        });
      }
      return workTypes;
    }
  }
  else if (response.statusCode == 403){
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
  }
  throw Exception('There might be a issue please login again');
}
