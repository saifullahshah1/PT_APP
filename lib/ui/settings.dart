import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../data/adminLog.dart';
import '../data/db.dart';
import 'widgets/input_dialog.dart';
import 'admin_log_screen.dart';  // Import the new screen

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<bool> _activationStatus;

  @override
  void initState() {
    super.initState();
    _activationStatus = _checkUserActivation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<bool>(
              future: _activationStatus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error loading activation status');
                } else if (snapshot.hasData && snapshot.data!) {
                  return ElevatedButton(
                    onPressed: () async {
                      await _deactivationApiCall();
                      setState(() {
                        _activationStatus = _checkUserActivation();
                      });
                    },
                    child: const Text('De-Activation', style: TextStyle(color: Colors.black)),
                  );
                } else {
                  return ElevatedButton(
                    onPressed: () async {
                      await _showInputDialog(context);
                      setState(() {
                        _activationStatus = _checkUserActivation();
                      });
                    },
                    child: const Text('Activation', style: TextStyle(color: Colors.black)),
                  );
                }
              },
            ),
            FutureBuilder<bool>(
              future: DatabaseHelper.instance.isDatabaseEmpty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData && snapshot.data == true) {
                  return ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Database is already empty!')),
                      );
                    },
                    child: const Text('Delete Records',
                        style: TextStyle(color: Colors.black)),
                  );
                } else {
                  return ElevatedButton(
                    onPressed: () async {
                      bool cleared = await DatabaseHelper.instance.clearDatabase();
                      if (cleared) {
                        adminLogCall("Records deleted");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Database cleared successfully!')),
                        );
                      }
                    },
                    child: const Text('Delete Records',
                        style: TextStyle(color: Colors.black)),
                  );
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminLogScreen()),
                );
              },
              child: const Text('Admin Log', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkUserActivation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('activatedUser') ?? false;
  }

  Future<void> _showInputDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return InputDialog();
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You entered: $result')),
      );
    }
  }

  Future<void> _deactivationApiCall() async {
    print('Deactivation Api Call...');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String licenseId = prefs.getString('licenseId') ?? '';
    String schoolId = prefs.getString('schoolId') ?? '';
    String issuedDate = prefs.getString('issuedDate') ?? '';
    String expiryDate = prefs.getString('expiryDate') ?? '';
    String path = "https://13.49.228.139/api/schools/$schoolId/licenses/$licenseId";

    final response = await http.put(
      Uri.parse(path),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'status': "deactivate",
        'issuedDate': issuedDate,
        'expiryDate': expiryDate,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setBool('activatedUser', false);
      await prefs.setString('licenseId', '');
      await prefs.setString('schoolId', '');
      await prefs.setString('issuedDate', '');
      await prefs.setString('expiryDate', '');
      print('License Deactivated');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('License Deactivated!')),
      );
    } else {
      print("${response.statusCode}\n${response.body}");
      print('Failed to deactivate license');
    }
  }
}
