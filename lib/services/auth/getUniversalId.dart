import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/services/auth/loggedIn.dart';
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';

Future<void> getUniversalId(
    String um_id, String aadharNumber) async {
  try {
    final url = Uri.parse(
        '${constants.baseUrl}/attendence_leave_api/get_user_universal_id.php?um_id=$um_id&adhar_no=$aadharNumber');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${constants.device_token}',
    });
    print(response.body);
    final responseData = jsonDecode(response.body);
    if (responseData['status'] == 'success') {
      constants.universalId = responseData['data']['emp_id'];
      constants.db = responseData['data']['db'];
      await LoggedIn.setUniversalId(responseData['data']['emp_id'],responseData['data']['db']);
    }
  } catch (error) {
    print('Error: $error');
  }
}
