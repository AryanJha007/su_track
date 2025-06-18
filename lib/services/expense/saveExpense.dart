import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import 'package:su_track/screens/expense/expense.dart';
import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> saveExpense({
  required BuildContext context,
  required String eventId,
  required String billDate,
  required String vendorName,
  required String place,
  required String billNo,
  required String particular,
  required List<Map<String, dynamic>> categories,
  required Function(String) onSuccess,
  required Function(String) onError,
}) async {
  final url = Uri.parse('${constants.baseUrl}/expenses_master_api/add_expense.php');
  final authData = await LoggedIn.getAuthData();
  final body = jsonEncode({
    'um_id': authData['um_Id'],
    'event_id': eventId,
    'bill_date': billDate,
    'vendor_name': vendorName,
    'place': place,
    'bill_no': billNo,
    'particular': particular,
    'categories': categories,
  });
  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${authData['token']}',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        onSuccess('Expense saved successfully');
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreen ()),
      );
      } else {
        onError(responseData['message']);
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
      final responseData = jsonDecode(response.body);
      onError(responseData['message']);
    }
  } catch (e) {
    onError('An error occurred');
  }
}
