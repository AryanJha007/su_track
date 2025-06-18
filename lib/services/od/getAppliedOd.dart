import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/getUniversalId.dart';
import '../auth/loggedIn.dart';

Future<List<Map<String, dynamic>>> fetchAppliedOd(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  String universalId = authData['universal_Id'];
  String db = authData['db'];
  final url = Uri.parse('${constants.baseUrl}/attendence_leave_api/get_applied_od.php?universal_id=$universalId&um_id=${authData['um_Id']}&db=$db');
  final response = await http.get(url, headers: {
    'Authorization': 'Bearer ${authData['token']}',});
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true && responseData['data'] is List) {
      return List<Map<String, dynamic>>.from(responseData['data']);
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );
      return [];
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
    return [];
  }
  else
    {
      throw Exception("Try again later");
    }
} 