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
            hintText: 'Enter license                                                                                             ',
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
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              validateLicense(_controller.text);
            }
          },
          child: const Text('Validate', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  void validateLicense(String key) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.black,
                ),
                SizedBox(width: 16),
                Text("Validating license..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      const path = "http://51.20.95.159/api/licenses/check/";

      final response = await http.post(
        Uri.parse(path + key),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'deviceName': _deviceName.toString(),
        }),
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        String licenseId = responseData['licenseId'];
        String schoolId = responseData['schoolId'];
        String issuedDate = responseData['issuedDate'];
        String expiryDate = responseData['expiryDate'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('activatedUser', true);
        await prefs.setString('licenseId', licenseId);
        await prefs.setString('schoolId', schoolId);
        await prefs.setString('issuedDate', issuedDate);
        await prefs.setString('expiryDate', expiryDate);

        print(prefs.getString('licenseId') ?? '');
        print(prefs.getString('schoolId') ?? '');
        print(prefs.getString('issuedDate') ?? '');
        print(prefs.getString('expiryDate') ?? '');

        print('License Validated');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activated!')),
        );
      } else {
        print(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('activatedUser', false);
        print('Failed to validate license');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to validate license')),
        );
      }
    } catch (e) {
      print(e);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      _deviceName = deviceName;
    });
  }
}
