import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<Map<String, dynamic>?> fetchProfile(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/profile_api/get_profile_api.php?um_id=${authData['um_Id']}');

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${authData['token']}',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return data['users'][0];
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
  } catch (e) {
    print('Error fetching profile: $e');
  }
  return null;
} 