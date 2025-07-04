import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import 'loggedIn.dart';

Future<void> logout(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/auth_api/logout.php');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer ${authData['token']}',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'um_id': authData['um_Id'],
    }),
  );
  print(response.body);
  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      await _clearAuthData();
      Future.delayed(Duration(milliseconds: 50), () {
        ScaffoldMessenger.of(context).clearSnackBars();
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>  (LoginPage()),
        ),
      );
    } else {

    }
  } else if (response.statusCode == 403) {
    await _clearAuthData();
    Future.delayed(Duration(milliseconds: 50), () {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>  (LoginPage()),
      ),
    );
  }
}

Future<void> _clearAuthData() async {
  await OneSignal.logout();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  constants.um_id = '';
  constants.username = '';
  constants.device_token = '';
  constants.aadhar = '';
  constants.universalId = '';
  constants.punch_status = '';
  constants.db='';
} 