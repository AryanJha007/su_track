import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';


Future<bool> updateAadhaar(String aadhaarNumber,BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/profile_api/update_adhar_api.php');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${authData['token']}',    },
    body: json.encode({
      'um_id': authData['um_Id'],
      'adhar_no': aadhaarNumber,
    }),
  );
  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      throw Exception('Failed to update Aadhaar: ${responseData['message']}');
    }
    return true;
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
  else {
    throw Exception('Failed to update Aadhaar. Status Code: ${response.statusCode}');
  }
  return false;
}
