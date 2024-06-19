import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InputDialog extends StatefulWidget {
  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _deviceName = 'Unknown';

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDeviceName();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter License'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Enter your valid school license',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter valid license';
            }
            return null;
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('activatedUser', false);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              validateLicense(_controller.text);
            }
          },
          child: const Text(
            'Validate',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  void validateLicense(String key) async {
    const path = "https://13.49.228.139/api/licenses/check/";

    final response = await http.post(
      Uri.parse(path + key),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'deviceName': _deviceName.toString(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      // Extract the relevant data from the response
      String licenseId = responseData['licenseId'];
      String schoolId = responseData['schoolId'];
      String expiryDate = responseData['expiryDate'];

      // Save data to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activatedUser', true);
      await prefs.setString('licenseId', licenseId);
      await prefs.setString('schoolId', schoolId);
      await prefs.setString('expiryDate', expiryDate);

      print(prefs.getString('licenseId') ?? '');
      print(prefs.getString('schoolId') ?? '');
      print(prefs.getString('expiryDate') ?? '');

      print('License Validated');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activated!')),
      );
      Navigator.of(context).pop();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activatedUser', false);
      print('Failed to validate license');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to validate license')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName;

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model ?? 'Unknown Android device';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name ?? 'Unknown iOS device';
      } else {
        deviceName = 'Unknown device';
      }
    } catch (e) {
      deviceName = 'Failed to get device name';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: Please check your connection')),
      );
    }

    setState(() {
      _deviceName = deviceName;
    });
  }
}
