import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/screens/aadhaar.dart';
import 'package:su_track/services/auth/getUniversalId.dart';
import 'package:su_track/services/auth/updateMobileToken.dart';
import 'package:su_track/util/constants.dart' as constants;

import '../../main.dart';
import '../../screens/auth/otpVerfication.dart';
import 'loggedIn.dart';

Future<bool> verifyOtp(String otp, BuildContext context) async {
  final otpResponse = await http.post(
    Uri.parse('${constants.baseUrl}/auth_api/otp_verification.php'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'username': constants.username,
      'um_id': constants.um_id,
      'otp': otp,
    }),
  );
  if (otpResponse.statusCode == 200) {
    final Map<String, dynamic> otpResponseData = jsonDecode(otpResponse.body);
    if (otpResponseData['success'] == true) {
      print(otpResponseData['data']);
      constants.um_id = otpResponseData['data']['um_id'];
      constants.username = otpResponseData['data']['username'];
      constants.device_token = otpResponseData['data']['device_token'];
      constants.aadhar = otpResponseData['data']['adhar_no'];
      constants.punch_status = otpResponseData['data']['punch_status'];
      constants.username = otpResponseData['data']['username'];
        if(otpResponseData['data']['adhar_no']==null)
          {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AadhaarPage()),
            );
          }
      await LoggedIn.saveAuthData(
        otpResponseData['data']['device_token'],
        otpResponseData['data']['um_id'],
        otpResponseData['data']['adhar_no'],
        otpResponseData['data']['username'],
      );
      await LoggedIn.savePunchingStatus(
          otpResponseData['data']['punch_status'] == '1');
      getUniversalId(otpResponseData['data']['um_id'],
          otpResponseData['data']['adhar_no']!);
      updateMobileToken(context);
      return true;
    }
  } else if (otpResponse.statusCode == 401) {
    final Map<String, dynamic> otpResponseData = jsonDecode(otpResponse.body);
    if (otpResponseData['success'] == false &&
        otpResponseData['message'] == 'Invalid OTP') {
      Future.delayed(Duration(milliseconds: 5), () {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter correct otp')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OTPVerificationCodeScreen()),
        );
      });
    }
  }
  return false;
}
