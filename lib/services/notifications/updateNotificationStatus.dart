import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> markNotificationAsRead(BuildContext context, String notificationId) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/notifications_api/update_is_read_notification.php?um_id=${authData['um_Id']}&notification_id=$notificationId');

  final response = await http.post(url, headers: {
    'Authorization': 'Bearer ${authData['token']}',
  });
  if (response.statusCode != 200) {
    throw Exception('Failed to update notification status');
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
} 