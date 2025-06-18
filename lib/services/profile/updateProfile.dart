import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/services/auth/getUniversalId.dart';
import 'package:su_track/util/constants.dart' as constants;
import  '../../screens/userScreen/profile.dart';
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> updateProfile(Map<String, dynamic> updatedData,BuildContext context) async {
  final url = Uri.parse('${constants.baseUrl}/profile_api/update_profile_api.php');
  final authData = await LoggedIn.getAuthData();
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${authData['token']}',
    },
    body: json.encode(updatedData),
  );
  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true) {
      getUniversalId(authData['umi_id'], updatedData['adhar_no']);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully',style: TextStyle(color: Colors.white),)),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
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
  else if (response.statusCode == 400){
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == false)
      {
        Future.delayed(Duration(milliseconds: 5), () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        });
      }
  }
}
