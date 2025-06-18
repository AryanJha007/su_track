import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<List<Map<String, dynamic>>> fetchNotifications(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/notifications_api/get_notifications_api.php?um_id=${authData['um_Id']}');

  final response = await http.get(url, headers: {
    'Authorization': 'Bearer ${authData['token']}',
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true && responseData['notifications'] is List) {
      return List<Map<String, dynamic>>.from(responseData['notifications']);
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

  throw Exception('Failed to load notifications');
} 