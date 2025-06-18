import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import 'loggedIn.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> updateMobileToken(BuildContext context) async {
  final authData = await LoggedIn.getAuthData();
  final response = await http.post(
    Uri.parse('${constants.baseUrl}/auth_api/update_mobile_token_api.php'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'um_id': authData['um_Id'],
      'mobile_token': await _getUserID(),
    }),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (responseData['success'] == true) {
    }
  }
}
Future<String?> _getUserID() async {
  final authData = await LoggedIn.getAuthData();
  try {
    await OneSignal.login(authData['um_Id']);
    return await OneSignal.User.getOnesignalId();
  } catch (e) {
    return null;
  }
}
