import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AdminLogScreen extends StatefulWidget {
  @override
  _AdminLogScreenState createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends State<AdminLogScreen> {
  late Future<List<dynamic>> _adminLogs;

  @override
  void initState() {
    super.initState();
    _adminLogs = _fetchAdminLogs();
  }

  Future<List<dynamic>> _fetchAdminLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String schoolId = prefs.getString('schoolId') ?? '';
    String path = "https://13.49.228.139/api/schools/$schoolId/adminlogs";

    final response = await http.get(
      Uri.parse(path),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Admin Logs'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _adminLogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading admin logs'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No admin logs found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var log = snapshot.data![index];
                return ListTile(
                  title: Text(log['action']),
                  subtitle: Text(log['timestamp']),
                  onTap: () {
                    // Optionally display more details about the log
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
