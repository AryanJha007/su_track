import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

Future<bool> login(String username, String password, BuildContext context) async {
  final response = await http.post(
    Uri.parse('${constants.baseUrl}/auth_api/login.php'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'username': username,
      'password': password,
      'mobile_token': 'abc123abc123abc123',
    }),
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (responseData['success'] == true) {
      constants.um_id = responseData['data']['um_id'];
      constants.username = responseData['data']['username'];
      return true;
    }
  }
  else
  {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(responseData['message'])),
    );
  }

  return false;
}

