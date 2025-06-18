import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/screens/expense/expense.dart';
import 'package:su_track/screens/expense/expenseShow.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> uploadFiles({
  required List<PlatformFile> selectedFiles,
  required String expenseTypeId,
  required BuildContext context,
}) async {
  try {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No files selected')),
      );
      return;
    }

    final authData = await LoggedIn.getAuthData();
    if (authData['token'] == null || authData['um_Id'] == null) {
      throw Exception('Authentication data missing');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${constants.baseUrl}/expenses_master_api/upload_bill_api.php'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer ${authData['token']}',
      'Content-Type': 'multipart/form-data',
    });

    // Add fields
    request.fields['expense_type_id'] = expenseTypeId;
    request.fields['um_id'] = authData['um_Id'];
    // Process each file
    for (var file in selectedFiles) {
      if (file.path == null) {
        print('Skipping file with null path: ${file.name}');
        continue;
      }

      // Get MIME type
      final mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
      final mimeTypeParts = mimeType.split('/');
      
      if (mimeTypeParts.length != 2) {
        continue;
      }

      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'bill_files[]',
          file.path!,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
        request.files.add(multipartFile);
      } catch (e) {
        continue;
      }
    }

    // Send request
    final streamedResponse = await request.send().timeout(
      Duration(minutes: 2),
      onTimeout: () {
        throw TimeoutException('Upload timed out');
      },
    );

    final response = await http.Response.fromStream(streamedResponse);


    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Files uploaded successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreen()),
      );
    } else if (response.statusCode == 403) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session expired. Please login again.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('Upload error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed. Please try again later.')),
      );
    }
  }
}
