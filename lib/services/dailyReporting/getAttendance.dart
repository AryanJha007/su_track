import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/services/auth/getUniversalId.dart';
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../../screens/dailyReporting/getAttendence.dart';
import '../auth/loggedIn.dart';

Future<Map<String, dynamic>> fetchAttendance(String umId, String yearMonth,BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  String username = authData['universal_Id'];
  String db = authData['db'];
  String um = authData['um_Id'];
  final url = Uri.parse('${constants.baseUrl}/attendence_leave_api/get_user_attendence.php?umid=$um&year_month=$yearMonth&username=$username&db=$db');

  final response = await http.get(url, headers: {
    'Authorization': 'Bearer ${authData['token']}',
  });
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      return responseData;
    }
    else if(responseData['success'] == false)
    {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The user has no attendance record')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => attendenceView()),
      );
    }
  }else if (response.statusCode == 403){
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
  throw Exception('Please try again later');

}