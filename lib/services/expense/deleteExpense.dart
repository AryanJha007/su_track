import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:su_track/screens/expense/expenseShow.dart';
import 'package:su_track/util/constants.dart' as constants;

import '../../screens/auth/login.dart';
import '../auth/loggedIn.dart';

Future<void> deleteExpense({
  required String expenseId,
  required BuildContext context,
}) async {
  final authData = await LoggedIn.getAuthData();
  final url = Uri.parse('${constants.baseUrl}/expenses_master_api/delete_expense.php?um_id=${authData['um_Id']}&expense_id=$expenseId');

  try {
    final response = await http.delete(url, headers: {
    'Authorization': 'Bearer ${authData['token']}',
    });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense deleted successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreenShow()),
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
        SnackBar(content: Text('Failed to delete expense')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}
