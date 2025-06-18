import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/getUniversalId.dart';
import '../auth/loggedIn.dart';

Future<List<Map<String, String>>> fetchLeaveTypes(BuildContext context) async {
  final currentYear = DateTime.now().year;
  final nextYear = currentYear + 1;
  final year = '$currentYear-$nextYear';
  final authData = await LoggedIn.getAuthData();
  String universalId = authData['universal_Id'];
  String db = authData['db'];
  final response = await http.get(
    Uri.parse('${constants.baseUrl}/attendence_leave_api/get_user_leaves.php?um_id=${authData['um_Id']}&year=$year&username=$universalId&db=$db'),
    headers: {
      'Authorization': 'Bearer ${authData['token']}',
    },
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData['success'] == true && responseData['data'] is List) {
      final List<dynamic> leaveList = responseData['data'];
      return leaveList.map((leave) {
        return {
          'leave_type': leave['leave_type']?.toString() ?? '',
          'leaves_allocated': leave['avlb_leaves']?.toString() ?? '0',
          'leave_id': leave['leave_id']?.toString() ?? '0',
          'leave_used': leave['leave_used']?.toString() ?? '0',
        };
      }).toList();
    }
    else {
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
  return [];
}
