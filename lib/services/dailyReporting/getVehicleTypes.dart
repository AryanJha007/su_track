import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:su_track/util/constants.dart' as constants;
import '../auth/loggedIn.dart';

Future<List<Map<String, String>>> fetchVehicleTypes(BuildContext context) async {
  try {
    final authData = await LoggedIn.getAuthData();

    final uri = Uri.parse('${constants.baseUrl}/daily_reporting_api/get_vehicle_types.php')
        .replace(queryParameters: {
      'um_id': authData['um_Id'],
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${authData['token']}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final List<dynamic> vehicleList = data['vehicle_types'];
        return vehicleList.map<Map<String, String>>((v) => {
          'vehicle_type_id': v['vehicle_type_id'].toString(),
          'vehicle_type': v['vehicle_type'],
        }).toList();
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to load vehicle types: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('An error occurred while fetching vehicle types');
  }
}
