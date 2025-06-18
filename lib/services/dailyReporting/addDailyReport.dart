import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:su_track/util/constants.dart' as constants;
import '../../screens/auth/login.dart';
import '../../screens/dailyReporting/dailyReporting.dart';
import '../auth/loggedIn.dart';
import 'package:http/http.dart' as http;

Future<void> submitDailyReport({
  required BuildContext context,
  required String workTypeId,
  required String status,
  String? remarks,
  String? vehicleType,
  String? vehicleNo,
  String? kilometers,
  XFile? file,
  required Function(String) onSuccess,
  required Function(String) onError,
}) async {
  DateTime now = DateTime.now();
  String formattedDate = '${now.toLocal()}'.split(' ')[0];
  String formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

  final authData = await LoggedIn.getAuthData();
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${constants.baseUrl}/daily_reporting_api/add_daily_report.php'),
  );

  request.headers.addAll({
    'Authorization': 'Bearer ${authData['token']}',
    'Content-Type': 'multipart/form-data',
  });

  request.fields['um_id'] = authData['um_Id'];
  request.fields['date'] = formattedDate;
  request.fields['time'] = formattedTime;
  request.fields['work_type_id'] = workTypeId;
  request.fields['status'] = status;
  request.fields['db'] = authData['db'];

  if (remarks != null) request.fields['remark'] = remarks;

  // Only send vehicle data if work_type_id = 1 and status = 1 or 6
  final isJourneyStatus = workTypeId == "1" && (status == "1" || status == "6");
  if (isJourneyStatus) {
    if (vehicleType != null) request.fields['vehicle_type_id'] = vehicleType;
    if (vehicleNo != null) request.fields['vehicle_no'] = vehicleNo;
    if (kilometers != null) request.fields['kilometers'] = kilometers;
  }

  if (file != null && isJourneyStatus) {
    String? mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      file.path,
      contentType: MediaType.parse(mimeType),
    ));
  }

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      onSuccess('Report submitted successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DailyReportingScreen()),
      );
    } else if (response.statusCode == 403) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are logged out due to duplicate session.')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    } else {
      onError('Failed to submit report: $responseBody');
    }
  } catch (e) {
    onError('Something went wrong. Please try again later.');
  }
}
