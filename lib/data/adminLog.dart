import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pt_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> adminLogCall(String adminLog) async {
  print('Admin Log Api Call...');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String schoolId = prefs.getString('schoolId') ?? '';
  String path = "http://51.20.95.159/api/schools/$schoolId/adminlogs";

  final response = await http.post(
    Uri.parse(path),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      "action": adminLog,
      "timestamp": getFormattedCurrentDateTime(),
      "details": {}
    }),
  );

  if (response.statusCode == 201) {
    print('Admin Log added');
  } else {
    print("${response.statusCode}\n${response.body}");
    print('Failed to add admin log');
  }
}

Future<void> getAllAdminLogs(String adminLog) async {
  print('Admin Log Api Call...');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String schoolId = prefs.getString('schoolId') ?? '';
  String path = "http://51.20.95.159/api/schools/$schoolId/adminlogs";

  final response = await http.get(
    Uri.parse(path),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 201) {
    print(response.body);
    print('Admin Log displayed');
  } else {
    print("${response.statusCode}\n${response.body}");
    print('Failed to display admin log');
  }
}