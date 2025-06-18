import 'package:http/http.dart' as http;
import 'package:su_track/screens/leave/applyLeave.dart';
import 'package:su_track/services/auth/getUniversalId.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> applyLeave({
  required String leaveId,
  required String appliedOnDate,
  required String fromDate,
  required String toDate,
  required String noOfDays,
  required String gatePass,
  required String leaveType,
  required String reason,
  required String leaveDuration,
  String? medicalDocument,
  required String halfDayType,
  required BuildContext context,
}) async {
  final url = Uri.parse('${constants.baseUrl}/attendence_leave_api/apply_leave.php');
  final authData = await LoggedIn.getAuthData();
  final request = http.MultipartRequest('POST', url)
    ..fields['um_id'] = authData['um_Id']
    ..fields['leave_id'] = leaveId
    ..fields['applied_on_date'] = appliedOnDate
    ..fields['from_date'] = fromDate
    ..fields['to_date'] = toDate
    ..fields['no_of_days'] = noOfDays
    ..fields['gate_pass'] = gatePass
    ..fields['leave_type'] = leaveType
    ..fields['reason'] = reason
    ..fields['leave_duration'] = leaveDuration
    ..fields['username'] = authData['universal_Id']
    ..fields['db'] = authData['db']
    ..fields['leave_contact_address'] = ""
    ..fields['leave_contact_no'] = ""
    ..fields['half_type'] = halfDayType
    ..fields['leave_contact_address'] = ""
    ..fields['from_time']="00:00:00"
    ..fields['to_time']="00:00:00"
    ..fields['EEmpId']='0'
    ..fields['ip_address'] = "0";
  if (medicalDocument != null) {
    request.files.add(await http.MultipartFile.fromPath('medical_document', medicalDocument));
  }
  request.headers.addAll({
    'Authorization': 'Bearer ${authData['token']}',
    'Content-Type': 'multipart/form-data',
  });
  try {
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave applied successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => (LeaveApplicationScreen()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Failed to apply ')),
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
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply leave')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred:')),
    );
  }
} 