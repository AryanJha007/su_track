import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../screens/od/odApply.dart';
import 'package:su_track/util/constants.dart' as constants;
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> applyOd(Map<String, dynamic> formData, String? documentPath, BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/attendence_leave_api/apply_od.php');
  final request = http.MultipartRequest('POST', url)
    ..headers.addAll({
      'Authorization': 'Bearer ${authData['token']}',
      'Content-Type': 'multipart/form-data',
    });

  formData.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  if (documentPath != null) {
    request.files.add(await http.MultipartFile.fromPath('od_document', documentPath));
  }
  try {
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    if (response.statusCode == 200 && data['success'] == true) {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OdApplicationScreen(),
          ),
        );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OD Applied Successfullyy')),
      );
    
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to apply OD')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred')),
    );
  }
}
