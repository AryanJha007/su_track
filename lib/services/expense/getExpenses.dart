import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<Map<String, dynamic>> fetchExpenses(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final response = await http.get(
    Uri.parse('${constants.baseUrl}/expenses_master_api/get_expense.php?um_id=${authData['um_Id']}'),
    headers: {
      'Authorization': 'Bearer ${authData['token']}',    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true  && responseData['expenses'] != null) {
      return {
        'total_expenses': responseData['total_expenses'],
        'expenses': List<Map<String, dynamic>>.from(responseData['expenses']),
      };
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
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
  return {'error': 'An error occurred'};

} 